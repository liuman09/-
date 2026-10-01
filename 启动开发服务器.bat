@echo off
chcp 65001 >nul
title Ecom Sandbox Dev Server
cd /d "%~dp0"

echo ============================================
echo   Ecom Sandbox - Starting...
echo ============================================
echo.

REM Kill existing process on port 8001
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8001 ^| findstr LISTENING') do (
    echo [Cleanup] Killing PID %%a on port 8001
    taskkill /F /PID %%a >nul 2>&1
    timeout /t 1 /nobreak >nul
)

if exist "node_modules\.bin\vite.cmd" (
    echo [OK] Dev server running at http://localhost:8001
    echo.
    start "" http://localhost:8001
    call "node_modules\.bin\vite.cmd" --port 8001 --host 0.0.0.0
) else (
    echo [ERROR] node_modules\.bin\vite.cmd not found
    echo Please run: npm install
    echo.
    pause
)