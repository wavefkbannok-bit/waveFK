@echo off
title waveFK Setup
color 0A
cls

echo.
echo  ==========================================
echo    waveFK - Home Assistant Setup
echo  ==========================================
echo.
echo  ขั้นตอนการติดตั้ง:
echo.
echo  [1] ติดตั้ง Node.js + n8n (ครั้งแรกเท่านั้น)
echo  [2] ตั้งค่า Bot + เชื่อม Claude API
echo  [3] ดูคู่มือสร้าง Telegram Bot
echo  [Q] ออก
echo.
set /p choice="เลือกขั้นตอน (1/2/3): "

if "%choice%"=="1" goto step1
if "%choice%"=="2" goto step2
if "%choice%"=="3" goto step3
if /i "%choice%"=="Q" exit
goto end

:step1
echo.
echo  กำลังรัน Step 1: ติดตั้ง Node.js + n8n...
echo  (ต้องรัน as Administrator)
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0\1-install.ps1""'"
goto end

:step2
echo.
echo  กำลังรัน Step 2: ตั้งค่า n8n อัตโนมัติ...
echo  (ต้องรัน 1-install.ps1 และเปิด n8n ไว้ก่อน)
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\2-autosetup.ps1"
goto end

:step3
echo.
echo  กำลังเปิดคู่มือสร้าง Telegram Bot...
start "" "%~dp0\telegram-guide.html"
goto end

:end
pause
