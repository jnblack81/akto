@echo off
REM ========================================
REM CRTP LAB - COMPLETE AUTOMATION LAUNCHER
REM Double-click this file to run everything
REM ========================================

echo.
echo ========================================
echo CRTP LAB AUTOMATION LAUNCHER
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Switching to correct branch...
git checkout claude/powershell-game-ad-installer-sbYrr
if errorlevel 1 (
    echo ERROR: Could not checkout branch
    pause
    exit /b 1
)

echo.
echo [2/3] Pulling latest changes...
git pull origin claude/powershell-game-ad-installer-sbYrr
if errorlevel 1 (
    echo ERROR: Could not pull changes
    pause
    exit /b 1
)

echo.
echo [3/3] Running automation script...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0AUTOMATE-EVERYTHING.ps1"

echo.
echo ========================================
echo Done!
echo ========================================
pause
