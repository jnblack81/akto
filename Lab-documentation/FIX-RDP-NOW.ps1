# ========================================
# FIX RDP ACCESS TO DCORP-STDADMIN
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "Fixing RDP access to dcorp-stdadmin..." -ForegroundColor Yellow
Write-Host ""

$vmName = "dcorp-stdadmin"
$user = "dollarcorp\Administrator"
$pass = "Psychi@Lab2024!"

Write-Host "Enabling RDP firewall rule..." -ForegroundColor White

$commands = @(
    "Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue",
    "New-NetFirewallRule -DisplayName 'RDP-Allow-All' -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -Enabled True -ErrorAction SilentlyContinue",
    "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name 'fDenyTSConnections' -Value 0",
    "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -Value '1' -Type String",
    "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUserName' -Value 'student' -Type String",
    "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword' -Value 'Password123!' -Type String",
    "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultDomainName' -Value 'dollarcorp' -Type String"
)

foreach ($cmd in $commands) {
    Write-Host "Running: $cmd" -ForegroundColor Gray

    $result = VBoxManage guestcontrol $vmName run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $user --password $pass --wait-stdout -- -Command $cmd 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Error: $result" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTING RDP ACCESS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing RDP to dcorp-stdadmin (192.168.96.50:3389)..." -ForegroundColor White

Start-Sleep -Seconds 3

$rdpTest = Test-NetConnection -ComputerName 192.168.96.50 -Port 3389 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

if ($rdpTest.TcpTestSucceeded) {
    Write-Host "  RDP ACCESS WORKING!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now RDP to 192.168.96.50" -ForegroundColor Green
    Write-Host "  Login: dollarcorp\student" -ForegroundColor White
    Write-Host "  Password: Password123!" -ForegroundColor White
    Write-Host ""
    Write-Host "Or just reboot dcorp-stdadmin and it will auto-login" -ForegroundColor Yellow
} else {
    Write-Host "  STILL BLOCKED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Open VirtualBox console for dcorp-stdadmin and run manually:" -ForegroundColor Yellow
    Write-Host "  Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'" -ForegroundColor White
}

Write-Host ""
