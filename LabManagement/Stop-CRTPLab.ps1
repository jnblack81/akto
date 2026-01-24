# ========================================
# STOP CRTP LAB ENVIRONMENT
# Gracefully shuts down all 10 VMs
# ========================================

param(
    [switch]$Force  # Force shutdown (poweroff) instead of graceful ACPI shutdown
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STOPPING CRTP LAB ENVIRONMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# VM shutdown order (member servers first, then DCs)
$VMs = @(
    # Member Servers (shutdown first)
    @{Name="dcorp-stdadmin"; IP="192.168.96.50"; Priority=1},
    @{Name="dcorp-sql1"; IP="192.168.96.26"; Priority=1},
    @{Name="dcorp-mssql"; IP="192.168.96.25"; Priority=1},
    @{Name="dcorp-mgmt"; IP="192.168.96.24"; Priority=1},
    @{Name="dcorp-ci"; IP="192.168.96.23"; Priority=1},
    @{Name="dcorp-appsrv"; IP="192.168.96.22"; Priority=1},
    @{Name="dcorp-adminsrv"; IP="192.168.96.21"; Priority=1},

    # Domain Controllers (shutdown last)
    @{Name="dcorp-dc"; IP="192.168.96.20"; Priority=2},
    @{Name="ecorp-dc"; IP="192.168.96.100"; Priority=2},
    @{Name="mcorp-dc"; IP="192.168.96.10"; Priority=2}
)

$shutdownMethod = if ($Force) { "poweroff" } else { "acpipowerbutton" }
$shutdownText = if ($Force) { "Force shutdown" } else { "Graceful shutdown" }

Write-Host "Shutdown method: $shutdownText" -ForegroundColor Yellow
Write-Host ""

# Shutdown Member Servers first
Write-Host "[PHASE 1] Shutting down Member Servers..." -ForegroundColor Yellow
Write-Host ""

foreach ($vm in ($VMs | Where-Object {$_.Priority -eq 1})) {
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "Shutting down $($vm.Name) ($($vm.IP))..." -ForegroundColor White

        if ($Force) {
            VBoxManage controlvm $vm.Name poweroff 2>&1 | Out-Null
        } else {
            VBoxManage controlvm $vm.Name acpipowerbutton 2>&1 | Out-Null
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Shutdown initiated" -ForegroundColor Green
        } else {
            Write-Host "  Failed to shutdown" -ForegroundColor Red
        }
    } else {
        Write-Host "$($vm.Name) - Already stopped" -ForegroundColor Gray
    }
}

if (-not $Force) {
    Write-Host ""
    Write-Host "Waiting 30 seconds for graceful shutdown..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Shutdown Domain Controllers
Write-Host ""
Write-Host "[PHASE 2] Shutting down Domain Controllers..." -ForegroundColor Yellow
Write-Host ""

foreach ($vm in ($VMs | Where-Object {$_.Priority -eq 2})) {
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "Shutting down $($vm.Name) ($($vm.IP))..." -ForegroundColor White

        if ($Force) {
            VBoxManage controlvm $vm.Name poweroff 2>&1 | Out-Null
        } else {
            VBoxManage controlvm $vm.Name acpipowerbutton 2>&1 | Out-Null
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Shutdown initiated" -ForegroundColor Green
        } else {
            Write-Host "  Failed to shutdown" -ForegroundColor Red
        }
    } else {
        Write-Host "$($vm.Name) - Already stopped" -ForegroundColor Gray
    }
    Start-Sleep -Seconds 2
}

if (-not $Force) {
    Write-Host ""
    Write-Host "Waiting 45 seconds for DCs to shutdown..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45
}

# Check final status
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL STATUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allStopped = $true
foreach ($vm in $VMs) {
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="poweroff"' -or $status -match 'VMState="aborted"' -or $status -match 'VMState="saved"') {
        Write-Host "$($vm.Name.PadRight(20)) $($vm.IP.PadRight(15)) STOPPED" -ForegroundColor Green
    } else {
        Write-Host "$($vm.Name.PadRight(20)) $($vm.IP.PadRight(15)) STILL RUNNING" -ForegroundColor Yellow
        $allStopped = $false
    }
}

Write-Host ""
if ($allStopped) {
    Write-Host "All VMs stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "Some VMs are still running. Run with -Force to force shutdown." -ForegroundColor Yellow
}
Write-Host ""
