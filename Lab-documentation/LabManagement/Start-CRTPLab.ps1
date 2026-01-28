# ========================================
# START CRTP LAB ENVIRONMENT
# Starts all 10 VMs - dcorp-stdadmin with GUI
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STARTING CRTP LAB ENVIRONMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# VM startup order (DCs first, then member servers)
$VMs = @(
    # Domain Controllers (start first)
    @{Name="mcorp-dc"; IP="192.168.96.10"; Priority=1},
    @{Name="ecorp-dc"; IP="192.168.96.100"; Priority=1},
    @{Name="dcorp-dc"; IP="192.168.96.20"; Priority=1},

    # Member Servers (start after DCs are up)
    @{Name="dcorp-adminsrv"; IP="192.168.96.21"; Priority=2},
    @{Name="dcorp-appsrv"; IP="192.168.96.22"; Priority=2},
    @{Name="dcorp-ci"; IP="192.168.96.23"; Priority=2},
    @{Name="dcorp-mgmt"; IP="192.168.96.24"; Priority=2},
    @{Name="dcorp-mssql"; IP="192.168.96.25"; Priority=2},
    @{Name="dcorp-sql1"; IP="192.168.96.26"; Priority=2},
    @{Name="dcorp-stdadmin"; IP="192.168.96.50"; Priority=2}
)

# Start Domain Controllers first (headless)
Write-Host "[PHASE 1] Starting Domain Controllers (headless)..." -ForegroundColor Yellow
Write-Host ""

foreach ($vm in ($VMs | Where-Object {$_.Priority -eq 1})) {
    Write-Host "Starting $($vm.Name) ($($vm.IP))..." -ForegroundColor White

    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "  Already running" -ForegroundColor Green
    } else {
        VBoxManage startvm $vm.Name --type headless 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Started successfully" -ForegroundColor Green
        } else {
            Write-Host "  Failed to start" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Waiting 60 seconds for DCs to boot..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Start Member Servers
Write-Host ""
Write-Host "[PHASE 2] Starting Member Servers..." -ForegroundColor Yellow
Write-Host ""

foreach ($vm in ($VMs | Where-Object {$_.Priority -eq 2})) {
    Write-Host "Starting $($vm.Name) ($($vm.IP))..." -ForegroundColor White

    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "  Already running" -ForegroundColor Green
    } else {
        # dcorp-stdadmin always starts with GUI
        $startMode = if ($vm.Name -eq "dcorp-stdadmin") { "gui" } else { "headless" }

        VBoxManage startvm $vm.Name --type $startMode 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            if ($vm.Name -eq "dcorp-stdadmin") {
                Write-Host "  Started with GUI - window will open" -ForegroundColor Green
            } else {
                Write-Host "  Started successfully" -ForegroundColor Green
            }
        } else {
            Write-Host "  Failed to start" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 2  # Small delay between starts
}

Write-Host ""
Write-Host "Waiting 30 seconds for member servers to boot..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check status
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL STATUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($vm in $VMs) {
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "$($vm.Name.PadRight(20)) $($vm.IP.PadRight(15)) RUNNING" -ForegroundColor Green
    } else {
        Write-Host "$($vm.Name.PadRight(20)) $($vm.IP.PadRight(15)) NOT RUNNING" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "CRTP Lab startup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "dcorp-stdadmin GUI window is open." -ForegroundColor Yellow
Write-Host "It will auto-login as dollarcorp\student : StudentPass123!" -ForegroundColor Yellow
Write-Host ""
