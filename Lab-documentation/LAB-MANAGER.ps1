# ========================================
# CRTP LAB MANAGER - Quick Launcher
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB MANAGER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start lab       - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Start-CRTPLab.ps1" -ForegroundColor Green
Write-Host "2. Stop lab        - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Stop-CRTPLab.ps1" -ForegroundColor Green
Write-Host "3. Test lab        - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Test-CRTPLab.ps1" -ForegroundColor Green
Write-Host "4. Snapshot lab    - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Snapshot-CRTPLab.ps1" -ForegroundColor Green
Write-Host "5. Restore lab     - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Restore-CRTPLab.ps1" -ForegroundColor Green
Write-Host "6. Check vulns     - " -NoNewline -ForegroundColor White
Write-Host ".\LabManagement\Test-CRTPVulnerabilities.ps1" -ForegroundColor Green
Write-Host ""

Write-Host "Quick actions:" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Enter number (1-6) or 'q' to quit"

switch ($choice) {
    "1" {
        Write-Host ""
        & .\LabManagement\Start-CRTPLab.ps1
    }
    "2" {
        Write-Host ""
        & .\LabManagement\Stop-CRTPLab.ps1
    }
    "3" {
        Write-Host ""
        & .\LabManagement\Test-CRTPLab.ps1
    }
    "4" {
        Write-Host ""
        & .\LabManagement\Snapshot-CRTPLab.ps1
    }
    "5" {
        Write-Host ""
        & .\LabManagement\Restore-CRTPLab.ps1 -ListSnapshots
    }
    "6" {
        Write-Host ""
        & .\LabManagement\Test-CRTPVulnerabilities.ps1
    }
    "q" {
        Write-Host "Exiting..." -ForegroundColor Yellow
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
    }
}

Write-Host ""
