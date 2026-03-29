# ============================================================
#  waveFK Test Runner
#  รัน Pester tests ทั้งหมดพร้อม code coverage report
#
#  วิธีใช้:
#    pwsh -File tests/RunTests.ps1
#
#  ต้องการ:
#    - PowerShell 7+ (pwsh)
#    - Pester v5: Install-Module Pester -MinimumVersion 5.0 -Force
# ============================================================

$ErrorActionPreference = "Stop"

# ── ตรวจสอบ Pester ─────────────────────────────────────────
$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    Write-Host ""
    Write-Host "[!!] ไม่พบ Pester กรุณาติดตั้งก่อน:" -ForegroundColor Red
    Write-Host "     Install-Module Pester -MinimumVersion 5.0 -Force" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if ($pester.Version -lt [version]"5.0") {
    Write-Host ""
    Write-Host "[!!] ต้องการ Pester v5 ขึ้นไป (พบ v$($pester.Version))" -ForegroundColor Red
    Write-Host "     Install-Module Pester -MinimumVersion 5.0 -Force" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Import-Module Pester -MinimumVersion 5.0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  waveFK - Test Suite" -ForegroundColor Cyan
Write-Host "  Pester v$($pester.Version)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── ตั้งค่า Pester ─────────────────────────────────────────
$config = New-PesterConfiguration

# ไฟล์ทดสอบ
$config.Run.Path = $PSScriptRoot
$config.Run.Exit = $false

# Output
$config.Output.Verbosity = "Detailed"

# Code Coverage
$config.CodeCoverage.Enabled        = $true
$config.CodeCoverage.Path           = @(
    (Resolve-Path "$PSScriptRoot\..\setup\1-install.ps1").Path,
    (Resolve-Path "$PSScriptRoot\..\setup\2-autosetup.ps1").Path
)
$config.CodeCoverage.OutputFormat   = "JaCoCo"
$config.CodeCoverage.OutputPath     = "$PSScriptRoot\coverage.xml"

# ── รัน Tests ──────────────────────────────────────────────
$result = Invoke-Pester -Configuration $config

# ── สรุปผล ─────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ผลการทดสอบ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ผ่าน  : $($result.PassedCount)" -ForegroundColor Green
if ($result.FailedCount -gt 0) {
    Write-Host "  ล้มเหลว: $($result.FailedCount)" -ForegroundColor Red
} else {
    Write-Host "  ล้มเหลว: 0" -ForegroundColor Gray
}
Write-Host "  ข้าม   : $($result.SkippedCount)" -ForegroundColor Gray
Write-Host "  รวม   : $($result.TotalCount)" -ForegroundColor White

if (Test-Path "$PSScriptRoot\coverage.xml") {
    Write-Host ""
    Write-Host "  Coverage report: tests\coverage.xml" -ForegroundColor DarkGray
}

Write-Host ""

if ($result.FailedCount -gt 0) {
    Write-Host "[!!] มี $($result.FailedCount) เทสที่ล้มเหลว" -ForegroundColor Red
    exit 1
} else {
    Write-Host "[OK] ทุกเทสผ่านหมด!" -ForegroundColor Green
    exit 0
}
