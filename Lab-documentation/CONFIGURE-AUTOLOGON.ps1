# ========================================
# CONFIGURE AUTO-LOGON FOR STUDENT WORKSTATION
# Run this on dcorp-stdadmin ONCE
# ========================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURE AUTO-LOGON" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Auto-logon credentials
$domain = "dollarcorp"
$username = "student"
$password = "Password123!"

Write-Host "Configuring auto-logon for: $domain\$username" -ForegroundColor Yellow
Write-Host ""

# Set registry keys for auto-logon
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Write-Host "Setting registry keys..." -ForegroundColor White

Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultUserName" -Value $username -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value $password -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value $domain -Type String

# Disable legal notice if it exists (blocks auto-logon)
$LegalNoticePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
if (Test-Path $LegalNoticePath) {
    Set-ItemProperty -Path $LegalNoticePath -Name "legalnoticecaption" -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $LegalNoticePath -Name "legalnoticetext" -Value "" -ErrorAction SilentlyContinue
}

Write-Host "  Registry keys set" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AUTO-LOGON CONFIGURED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next boot will automatically log in as: $domain\$username" -ForegroundColor Green
Write-Host ""
Write-Host "To test, restart this VM:" -ForegroundColor Yellow
Write-Host "  Restart-Computer" -ForegroundColor White
Write-Host ""
