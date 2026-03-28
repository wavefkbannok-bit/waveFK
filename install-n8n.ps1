# ===================================================
# n8n Installation Script for Windows
# Run as Administrator in PowerShell
# ===================================================

Write-Host "=== n8n Installer ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] Please run this script as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell > 'Run as administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Step 2: Install Chocolatey (package manager) if not installed
Write-Host "[1/5] Checking Chocolatey..." -ForegroundColor Yellow
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor Green
}

# Step 3: Install Node.js LTS (v20) - required for n8n
Write-Host ""
Write-Host "[2/5] Installing Node.js v20 LTS (required for n8n)..." -ForegroundColor Yellow
Write-Host "Note: Your current Node.js v25 is too new for n8n" -ForegroundColor Red
choco install nodejs-lts --version=20.19.1 -y --force
refreshenv

# Verify Node.js version
$nodeVersion = node -v 2>$null
Write-Host "Node.js version: $nodeVersion" -ForegroundColor Cyan

# Step 4: Install Windows Build Tools (fixes gyp errors)
Write-Host ""
Write-Host "[3/5] Installing Windows Build Tools (fixes gyp ERR!)..." -ForegroundColor Yellow
npm install -g windows-build-tools --vs2019
# Alternative if above fails:
# choco install visualstudio2019buildtools -y

# Step 5: Clear npm cache and old failed n8n install
Write-Host ""
Write-Host "[4/5] Cleaning up old installation..." -ForegroundColor Yellow
npm cache clean --force
npm uninstall -g n8n 2>$null

# Step 6: Install n8n
Write-Host ""
Write-Host "[5/5] Installing n8n..." -ForegroundColor Yellow
npm install -g n8n

# Verify installation
Write-Host ""
$n8nVersion = n8n --version 2>$null
if ($n8nVersion) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  n8n installed successfully!" -ForegroundColor Green
    Write-Host "  Version: $n8nVersion" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To start n8n, run:" -ForegroundColor Cyan
    Write-Host "  n8n start" -ForegroundColor White
    Write-Host ""
    Write-Host "Then open browser: http://localhost:5678" -ForegroundColor Cyan
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Installation may have failed." -ForegroundColor Red
    Write-Host "  Try the manual steps below:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual fix option - use npx instead:" -ForegroundColor Yellow
    Write-Host "  npx n8n" -ForegroundColor White
}

Write-Host ""
pause
