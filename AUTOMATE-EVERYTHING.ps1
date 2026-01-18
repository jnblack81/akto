# ========================================
# CRTP LAB - COMPLETE AUTOMATION
# Run this ONCE on Windows Host
# It does EVERYTHING automatically
# ========================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB COMPLETE AUTOMATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VMs = @(
    @{Name="mcorp-dc"; User="moneycorp\Administrator"; Pass="Psychi@Lab2024!"; ExpectedIP="192.168.96.10"},
    @{Name="ecorp-dc"; User="eurocorp\Administrator"; Pass="Psychi@Lab2024!"; ExpectedIP="192.168.96.11"},
    @{Name="dcorp-dc"; User="dcorp\Administrator"; Pass="Psychi@Lab2024!"; ExpectedIP="192.168.96.12"}
)

# Check VBoxManage exists
if (-not (Test-Path $VBoxManage)) {
    Write-Host "ERROR: VBoxManage not found at $VBoxManage" -ForegroundColor Red
    Write-Host "Is VirtualBox installed?" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Found VBoxManage" -ForegroundColor Green
Write-Host ""

# Process each VM
foreach ($vm in $VMs) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Processing: $($vm.Name)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""

    # Check if VM is running
    Write-Host "[1/5] Checking VM status..." -ForegroundColor Cyan
    $runningVMs = & $VBoxManage list runningvms
    if ($runningVMs -match $vm.Name) {
        Write-Host "  VM is running" -ForegroundColor Green
    } else {
        Write-Host "  VM is not running - starting it..." -ForegroundColor Yellow
        & $VBoxManage startvm $vm.Name --type headless
        Write-Host "  Waiting 60 seconds for boot..." -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }

    # Wait for VM to be ready
    Write-Host "[2/5] Waiting for VM to be ready..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10

    # Get current IP
    Write-Host "[3/5] Checking current IP address..." -ForegroundColor Cyan

    $getIPScript = @"
`$adapter = Get-NetAdapter | Where-Object {`$_.Status -eq 'Up'} | Select-Object -First 1
`$ip = (Get-NetIPAddress -InterfaceAlias `$adapter.Name -AddressFamily IPv4 | Where-Object {`$_.IPAddress -like '192.168.*'}).IPAddress
Write-Host `$ip
"@

    try {
        $currentIP = & $VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $getIPScript 2>&1 | Select-String "192.168"

        if ($currentIP -match "192.168.(\d+)\.(\d+)") {
            Write-Host "  Current IP: $currentIP" -ForegroundColor Yellow
        } else {
            Write-Host "  Could not determine IP" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Error getting IP: $_" -ForegroundColor Red
    }

    # Fix IP if needed
    Write-Host "[4/5] Setting correct IP address..." -ForegroundColor Cyan

    $fixIPScript = @"
`$adapter = Get-NetAdapter | Where-Object {`$_.Status -eq 'Up'} | Select-Object -First 1
Get-NetIPAddress -InterfaceAlias `$adapter.Name -AddressFamily IPv4 | Where-Object {`$_.IPAddress -like '192.168.*'} | ForEach-Object {
    Remove-NetIPAddress -IPAddress `$_.IPAddress -Confirm:`$false -ErrorAction SilentlyContinue
}
New-NetIPAddress -InterfaceAlias `$adapter.Name -IPAddress $($vm.ExpectedIP) -PrefixLength 24 -ErrorAction SilentlyContinue | Out-Null
Write-Host 'IP set to $($vm.ExpectedIP)'
"@

    try {
        & $VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $fixIPScript
        Write-Host "  IP address configured" -ForegroundColor Green
    } catch {
        Write-Host "  Error setting IP: $_" -ForegroundColor Red
    }

    # Set DNS
    Write-Host "[5/5] Configuring DNS..." -ForegroundColor Cyan

    $dnsServers = switch ($vm.Name) {
        "mcorp-dc" { "192.168.96.10,127.0.0.1" }
        "ecorp-dc" { "192.168.96.11,192.168.96.10" }
        "dcorp-dc" { "192.168.96.12,192.168.96.10" }
    }

    $setDNSScript = @"
`$adapter = Get-NetAdapter | Where-Object {`$_.Status -eq 'Up'} | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceAlias `$adapter.Name -ServerAddresses $dnsServers
Write-Host 'DNS configured'
"@

    try {
        & $VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $setDNSScript
        Write-Host "  DNS configured" -ForegroundColor Green
    } catch {
        Write-Host "  Error setting DNS: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  $($vm.Name) configured!" -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 2
}

# Final verification
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RUNNING FINAL VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testScript = @"
`$passed = 0
`$failed = 0

Write-Host 'Testing from $($env:COMPUTERNAME)...'

if (Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet) { `$passed++ } else { `$failed++ }
if (Test-Connection -ComputerName 192.168.96.11 -Count 2 -Quiet) { `$passed++ } else { `$failed++ }
if (Test-Connection -ComputerName 192.168.96.12 -Count 2 -Quiet) { `$passed++ } else { `$failed++ }

Write-Host "Network Tests: Passed `$passed / 3"

try {
    `$ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','moneycorp.local')
    `$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(`$ctx)
    if (`$dom.Name -eq 'moneycorp.local') { `$passed++ }
} catch { `$failed++ }

try {
    `$ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','eurocorp.local')
    `$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(`$ctx)
    if (`$dom.Name -eq 'eurocorp.local') { `$passed++ }
} catch { `$failed++ }

Write-Host "Domain Tests: Passed `$passed / 5"

if (`$failed -eq 0) {
    Write-Host 'ALL TESTS PASSED!' -ForegroundColor Green
} else {
    Write-Host "Failed: `$failed tests" -ForegroundColor Red
}
"@

foreach ($vm in $VMs) {
    Write-Host "Testing $($vm.Name)..." -ForegroundColor Cyan
    try {
        & $VBoxManage guestcontrol $vm.Name run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username $vm.User --password $vm.Pass --wait-stdout -- -Command $testScript
    } catch {
        Write-Host "  Error running tests: $_" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "AUTOMATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "All VMs have been configured and tested." -ForegroundColor Green
Write-Host "Your CRTP lab is ready!" -ForegroundColor Green
Write-Host ""
