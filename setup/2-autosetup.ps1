# ============================================================
#  waveFK Step 2: Auto-configure n8n
#  ใส่ API Keys แล้วสคริปต์จะตั้งค่าทุกอย่างให้อัตโนมัติ
# ============================================================

$ErrorActionPreference = "Stop"
$n8nUrl  = "http://localhost:5678"
$apiBase = "$n8nUrl/api/v1"

function Write-Step($msg) { Write-Host "`n[>>] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "[!!] $msg" -ForegroundColor Red; pause; exit 1 }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  waveFK - Auto Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "สคริปต์นี้จะตั้งค่า n8n ให้อัตโนมัติ" -ForegroundColor White
Write-Host "คุณต้องใส่ข้อมูล 2 อย่างเท่านั้น:" -ForegroundColor White
Write-Host ""

# ── รับ Input จากผู้ใช้ ─────────────────────────────────────
Write-Host "1. Telegram Bot Token" -ForegroundColor Yellow
Write-Host "   (ได้จาก @BotFather ใน Telegram - ดู telegram-guide.html ถ้ายังไม่มี)" -ForegroundColor DarkGray
$TelegramToken = Read-Host "   ใส่ Bot Token"

Write-Host ""
Write-Host "2. Claude (Anthropic) API Key" -ForegroundColor Yellow
Write-Host "   (ได้จาก https://console.anthropic.com/)" -ForegroundColor DarkGray
$AnthropicKey = Read-Host "   ใส่ API Key"

if ([string]::IsNullOrWhiteSpace($TelegramToken) -or [string]::IsNullOrWhiteSpace($AnthropicKey)) {
    Write-Fail "กรุณาใส่ข้อมูลให้ครบทั้ง 2 อย่าง"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray

# ── 1. รอให้ n8n พร้อม ──────────────────────────────────────
Write-Step "รอให้ n8n เริ่มทำงาน..."
$tries = 0
do {
    Start-Sleep -Seconds 3
    $tries++
    try {
        $r = Invoke-WebRequest -Uri "$n8nUrl/healthz" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $ready = ($r.StatusCode -eq 200)
    } catch { $ready = $false }
    if (-not $ready) { Write-Host "  รอ... ($tries)" -ForegroundColor DarkGray }
    if ($tries -ge 20) { Write-Fail "n8n ไม่ตอบสนอง กรุณารัน 1-install.ps1 ก่อน" }
} while (-not $ready)
Write-OK "n8n พร้อมแล้ว"

# ── 2. Setup owner account ───────────────────────────────────
Write-Step "สร้างบัญชี n8n..."
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$ownerEmail = "admin@wavefk.local"
$ownerPass  = "waveFK@Admin2026!"

try {
    $setupBody = @{
        email     = $ownerEmail
        firstName = "waveFK"
        lastName  = "Admin"
        password  = $ownerPass
    } | ConvertTo-Json

    Invoke-WebRequest -Uri "$apiBase/owner/setup" `
        -Method POST -Body $setupBody `
        -ContentType "application/json" `
        -WebSession $session -UseBasicParsing -ErrorAction Stop | Out-Null
    Write-OK "สร้างบัญชีสำเร็จ"
} catch {
    # อาจตั้งค่าไปแล้ว ให้ login แทน
    Write-Host "  บัญชีมีอยู่แล้ว กำลัง login..." -ForegroundColor DarkGray
}

# ── 3. Login ─────────────────────────────────────────────────
Write-Step "เข้าสู่ระบบ n8n..."
$loginBody = @{ email = $ownerEmail; password = $ownerPass } | ConvertTo-Json
try {
    Invoke-WebRequest -Uri "$apiBase/users/login" `
        -Method POST -Body $loginBody `
        -ContentType "application/json" `
        -WebSession $session -UseBasicParsing -ErrorAction Stop | Out-Null
    Write-OK "Login สำเร็จ"
} catch {
    Write-Fail "Login ไม่สำเร็จ: $($_.Exception.Message)"
}

# ── 4. ดึง CSRF Token (n8n 1.x ต้องการ) ─────────────────────
try {
    $csrf = $session.Cookies.GetCookies($n8nUrl) | Where-Object { $_.Name -eq "n8n-auth" } | Select-Object -First 1
} catch {}

# Helper: POST กับ session
function Invoke-N8nPost($path, $body) {
    $headers = @{ "Content-Type" = "application/json" }
    return Invoke-RestMethod -Uri "$apiBase$path" `
        -Method POST -Body ($body | ConvertTo-Json -Depth 10) `
        -Headers $headers -WebSession $session
}

# ── 5. สร้าง Telegram Credential ─────────────────────────────
Write-Step "สร้าง Telegram credential..."
try {
    $telegramCred = Invoke-N8nPost "/credentials" @{
        name = "Telegram Bot"
        type = "telegramApi"
        data = @{ accessToken = $TelegramToken }
    }
    $telegramCredId = $telegramCred.id
    Write-OK "สร้าง Telegram credential สำเร็จ (ID: $telegramCredId)"
} catch {
    Write-Fail "สร้าง Telegram credential ไม่สำเร็จ: $($_.Exception.Message)"
}

# ── 6. สร้าง Claude API Credential ───────────────────────────
Write-Step "สร้าง Claude API credential..."
try {
    $claudeCred = Invoke-N8nPost "/credentials" @{
        name = "Claude API Key"
        type = "httpHeaderAuth"
        data = @{ name = "x-api-key"; value = $AnthropicKey }
    }
    $claudeCredId = $claudeCred.id
    Write-OK "สร้าง Claude credential สำเร็จ (ID: $claudeCredId)"
} catch {
    Write-Fail "สร้าง Claude credential ไม่สำเร็จ: $($_.Exception.Message)"
}

# ── 7. โหลดและอัปเดต Workflow JSON ───────────────────────────
Write-Step "อัปเดต workflow ด้วย credential IDs..."
$workflowPath = Join-Path $PSScriptRoot "..\workflow\telegram-claude-bot.json"
$workflowJson = Get-Content $workflowPath -Raw

# แทนที่ credential IDs
$workflowJson = $workflowJson -replace '"id": "telegram-cred"', "`"id`": `"$telegramCredId`""
$workflowJson = $workflowJson -replace '"id": "claude-cred"', "`"id`": `"$claudeCredId`""
$workflow = $workflowJson | ConvertFrom-Json

# ── 8. Import Workflow ────────────────────────────────────────
Write-Step "Import workflow เข้า n8n..."
try {
    $importResult = Invoke-N8nPost "/workflows" $workflow
    $workflowId = $importResult.id
    Write-OK "Import workflow สำเร็จ (ID: $workflowId)"
} catch {
    Write-Fail "Import workflow ไม่สำเร็จ: $($_.Exception.Message)"
}

# ── 9. Activate Workflow ──────────────────────────────────────
Write-Step "เปิดใช้งาน workflow..."
try {
    Invoke-RestMethod -Uri "$apiBase/workflows/$workflowId/activate" `
        -Method POST -WebSession $session | Out-Null
    Write-OK "Activate สำเร็จ"
} catch {
    Write-Fail "Activate ไม่สำเร็จ: $($_.Exception.Message)"
}

# ── 10. สรุปผล ────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ตั้งค่าเสร็จสมบูรณ์!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Bot ของคุณพร้อมใช้งานแล้ว!" -ForegroundColor White
Write-Host ""
Write-Host "ทดสอบ:" -ForegroundColor Yellow
Write-Host "  1. เปิด Telegram" -ForegroundColor White
Write-Host "  2. หา Bot ที่คุณสร้างไว้" -ForegroundColor White
Write-Host "  3. ส่งข้อความ: สวัสดี" -ForegroundColor White
Write-Host "  4. รอ Claude ตอบกลับ (3-5 วินาที)" -ForegroundColor White
Write-Host ""
Write-Host "จัดการ n8n:" -ForegroundColor Yellow
Write-Host "  URL: http://localhost:5678" -ForegroundColor White
Write-Host "  Email: $ownerEmail" -ForegroundColor White
Write-Host "  Password: $ownerPass" -ForegroundColor White
Write-Host ""
Start-Process "http://localhost:5678"
pause
