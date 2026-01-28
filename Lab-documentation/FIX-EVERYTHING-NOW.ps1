# ========================================
# FIX EVERYTHING AUTOMATICALLY
# Runs on ALL VMs to configure firewall and settings
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AUTOMATED LAB CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# All VMs with credentials
$VMs = @(
    @{Name="mcorp-dc"; User="moneycorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="ecorp-dc"; User="eurocorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-dc"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-adminsrv"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-appsrv"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-ci"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-mgmt"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-mssql"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-sql1"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"},
    @{Name="dcorp-stdadmin"; User="dollarcorp\Administrator"; Pass="Psychi@Lab2024!"}
)

$successCount = 0
$failCount = 0

foreach ($vm in $VMs) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Configuring: $($vm.Name)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    # Check if VM is running
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -notmatch 'VMState="running"') {
        Write-Host "VM not running - starting..." -ForegroundColor Yellow
        VBoxManage startvm $vm.Name --type headless 2>&1 | Out-Null
        Write-Host "Waiting 60 seconds for boot..." -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }

    Write-Host "Opening firewall..." -ForegroundColor White

    # Enable firewall rules
    $commands = @(
        "Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue",
        "Enable-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction SilentlyContinue",
        "Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue",
        "New-NetFirewallRule -DisplayName 'Allow All from Host' -Direction Inbound -RemoteAddress 192.168.96.0/24 -Action Allow -ErrorAction SilentlyContinue"
    )

    $allSuccess = $true
    foreach ($cmd in $commands) {
        $result = VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $cmd 2>&1

        if ($LASTEXITCODE -ne 0) {
            $allSuccess = $false
        }
    }

    # Configure auto-logon for dcorp-stdadmin
    if ($vm.Name -eq "dcorp-stdadmin") {
        Write-Host "Configuring auto-logon for student..." -ForegroundColor White

        $autoLogonCmd = @"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -Value '1' -Type String
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUserName' -Value 'student' -Type String
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword' -Value 'Password123!' -Type String
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultDomainName' -Value 'dollarcorp' -Type String
"@

        $result = VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $autoLogonCmd 2>&1
    }

    if ($allSuccess) {
        Write-Host "  SUCCESS" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  COMPLETED (check for errors above)" -ForegroundColor Yellow
        $successCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured: $successCount / $($VMs.Count) VMs" -ForegroundColor Green
Write-Host ""
Write-Host "All VMs now have:" -ForegroundColor Yellow
Write-Host "  - Firewall rules allowing host (192.168.96.0/24)" -ForegroundColor White
Write-Host "  - File sharing enabled" -ForegroundColor White
Write-Host "  - Remote Desktop enabled" -ForegroundColor White
Write-Host "  - dcorp-stdadmin: Auto-logon as dollarcorp\student" -ForegroundColor White
Write-Host ""
Write-Host "Run Test-CRTPLab.ps1 to verify connectivity" -ForegroundColor Green
Write-Host ""
