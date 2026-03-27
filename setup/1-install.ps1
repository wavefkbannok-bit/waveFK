# ============================================================
#  waveFK Step 1: Install Node.js + n8n
#  รันด้วย PowerShell as Administrator
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n[>>] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "[!!] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  waveFK - Auto Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ── 1. ตรวจสอบ Node.js ──────────────────────────────────────
Write-Step "ตรวจสอบ Node.js..."
$nodeInstalled = $false
try {
    $nodeVer = (node --version 2>&1).ToString()
    if ($nodeVer -match "v\d+") {
        Write-OK "Node.js ติดตั้งแล้ว: $nodeVer"
        $nodeInstalled = $true
    }
} catch {}

if (-not $nodeInstalled) {
    Write-Step "ติดตั้ง Node.js LTS..."

    # ลองใช้ winget ก่อน (Windows 11 / Windows 10 updated)
    $wingetOk = $false
    try {
        winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -e 2>&1 | Out-Null
        $wingetOk = $true
        Write-OK "ติดตั้ง Node.js ผ่าน winget สำเร็จ"
    } catch {}

    # ถ้า winget ไม่มี ให้ดาวน์โหลดตรง
    if (-not $wingetOk) {
        Write-Step "winget ไม่พบ กำลังดาวน์โหลด Node.js installer..."
        $nodeUrl = "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
        $installer = "$env:TEMP\node-installer.msi"
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installer
        Write-Step "กำลังติดตั้ง Node.js (อาจใช้เวลา 1-2 นาที)..."
        Start-Process msiexec.exe -ArgumentList "/i `"$installer`" /quiet /norestart" -Wait
        Write-OK "ติดตั้ง Node.js สำเร็จ"
    }

    # รีเฟรช PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ── 2. ตรวจสอบ n8n ──────────────────────────────────────────
Write-Step "ตรวจสอบ n8n..."
$n8nInstalled = $false
try {
    $n8nVer = (n8n --version 2>&1).ToString()
    if ($n8nVer -match "\d+\.\d+") {
        Write-OK "n8n ติดตั้งแล้ว: $n8nVer"
        $n8nInstalled = $true
    }
} catch {}

if (-not $n8nInstalled) {
    Write-Step "ติดตั้ง n8n (อาจใช้เวลา 3-5 นาที)..."
    npm install -g n8n
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "ติดตั้ง n8n ไม่สำเร็จ"
        Write-Host "กรุณารัน PowerShell as Administrator แล้วลองใหม่" -ForegroundColor Yellow
        pause
        exit 1
    }
    Write-OK "ติดตั้ง n8n สำเร็จ"
}

# ── 3. เริ่ม n8n ──────────────────────────────────────────────
Write-Step "กำลังเริ่ม n8n..."
Write-Host ""
Write-Host "  n8n จะเปิดที่: http://localhost:5678" -ForegroundColor Yellow
Write-Host "  เมื่อ n8n พร้อมแล้ว ให้รัน: 2-autosetup.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "  (กด Ctrl+C เพื่อหยุด n8n)" -ForegroundColor DarkGray
Write-Host ""

# เปิดเบราว์เซอร์หลังจาก 5 วินาที
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 6
    Start-Process "http://localhost:5678"
} | Out-Null

n8n start
