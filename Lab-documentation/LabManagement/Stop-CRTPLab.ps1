# ========================================
# STOP CRTP LAB ENVIRONMENT
# Force shuts down all 10 VMs
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STOPPING CRTP LAB ENVIRONMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Shutting down all VMs gracefully..." -ForegroundColor Yellow
Write-Host ""

# VM shutdown order (member servers first, then DCs)
$VMs = @(
    # Member Servers (shutdown first)
    "dcorp-stdadmin",
    "dcorp-sql1",
    "dcorp-mssql",
    "dcorp-mgmt",
    "dcorp-ci",
    "dcorp-appsrv",
    "dcorp-adminsrv",
    # Domain Controllers (shutdown last)
    "dcorp-dc",
    "ecorp-dc",
    "mcorp-dc"
)

foreach ($vmName in $VMs) {
    $status = VBoxManage showvminfo $vmName --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "Shutting down $vmName..." -ForegroundColor White

        # Use poweroff for immediate shutdown
        $result = VBoxManage controlvm $vmName poweroff 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Powered off" -ForegroundColor Green
        } else {
            Write-Host "  Error: $result" -ForegroundColor Red
        }

        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "$vmName - Already stopped" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Waiting 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check final status
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL STATUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allStopped = $true
foreach ($vmName in $VMs) {
    $status = VBoxManage showvminfo $vmName --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="poweroff"' -or $status -match 'VMState="aborted"' -or $status -match 'VMState="saved"') {
        Write-Host "$($vmName.PadRight(20)) STOPPED" -ForegroundColor Green
    } else {
        Write-Host "$($vmName.PadRight(20)) STILL RUNNING" -ForegroundColor Red
        $allStopped = $false
    }
}

Write-Host ""
if ($allStopped) {
    Write-Host "All VMs stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Some VMs are still running!" -ForegroundColor Red
    Write-Host "Manually stop them with: VBoxManage controlvm <vm-name> poweroff" -ForegroundColor Yellow
}
Write-Host ""
