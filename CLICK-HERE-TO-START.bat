@echo off
REM ====================================================================
REM IF YOU SEE THIS FILE, DOUBLE-CLICK IT TO START THE AUTOMATION
REM ====================================================================

echo.
echo ========================================
echo CRTP LAB COMPLETE AUTOMATION
echo ========================================
echo.
echo This will automatically configure your entire CRTP lab.
echo.
echo Press any key to start...
pause >nul

cd /d "%~dp0"

echo.
echo [Step 1/3] Switching to correct branch...
git checkout claude/powershell-game-ad-installer-sbYrr
if errorlevel 1 (
    echo.
    echo ERROR: Could not checkout branch
    echo.
    echo Run this in PowerShell:
    echo    cd D:\Tooling\akto
    echo    git checkout claude/powershell-game-ad-installer-sbYrr
    echo.
    pause
    exit /b 1
)

echo.
echo [Step 2/3] Getting latest files...
git pull origin claude/powershell-game-ad-installer-sbYrr

echo.
echo [Step 3/3] Starting VM automation...
echo.
echo This will now:
echo   - Start all 3 VMs if not running
echo   - Fix IP addresses automatically
echo   - Configure DNS
echo   - Test everything
echo.
timeout /t 3 >nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0AUTOMATE-EVERYTHING.ps1"

echo.
echo ========================================
echo COMPLETE!
echo ========================================
echo.
pause
