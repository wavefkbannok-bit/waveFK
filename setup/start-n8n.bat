@echo off
title waveFK - n8n Home Assistant
color 0A

echo ========================================
echo   waveFK - Home Assistant
echo   กำลังเริ่ม n8n...
echo ========================================
echo.

:: ตรวจสอบว่ามี Node.js ติดตั้งแล้วหรือยัง
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ไม่พบ Node.js กรุณาติดตั้งจาก https://nodejs.org/
    echo        เลือก LTS version แล้วลองใหม่
    pause
    exit /b 1
)

:: ตรวจสอบว่ามี n8n ติดตั้งแล้วหรือยัง
n8n --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] ไม่พบ n8n กำลังติดตั้ง...
    echo       (อาจใช้เวลา 2-3 นาที)
    echo.
    npm install -g n8n
    if %errorlevel% neq 0 (
        echo [ERROR] ติดตั้ง n8n ไม่สำเร็จ ลองรัน CMD as Administrator
        pause
        exit /b 1
    )
)

echo [OK] Node.js และ n8n พร้อมใช้งาน
echo.
echo กำลังเปิด n8n...
echo เปิดเบราว์เซอร์แล้วไปที่: http://localhost:5678
echo.
echo กด Ctrl+C เพื่อหยุด n8n
echo ========================================
echo.

:: รัน n8n
n8n start
pause
