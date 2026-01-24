# ========================================
# RESTORE CRTP LAB ENVIRONMENT
# Reverts all VMs to a specific snapshot
# ========================================

param(
    [string]$SnapshotName = "",  # Snapshot name to restore
    [switch]$Latest,             # Restore to latest snapshot
    [switch]$ListSnapshots       # List available snapshots
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESTORE CRTP LAB ENVIRONMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# All VMs
$VMs = @(
    @{Name="mcorp-dc"; IP="192.168.96.10"},
    @{Name="ecorp-dc"; IP="192.168.96.100"},
    @{Name="dcorp-dc"; IP="192.168.96.20"},
    @{Name="dcorp-adminsrv"; IP="192.168.96.21"},
    @{Name="dcorp-appsrv"; IP="192.168.96.22"},
    @{Name="dcorp-ci"; IP="192.168.96.23"},
    @{Name="dcorp-mgmt"; IP="192.168.96.24"},
    @{Name="dcorp-mssql"; IP="192.168.96.25"},
    @{Name="dcorp-sql1"; IP="192.168.96.26"},
    @{Name="dcorp-stdadmin"; IP="192.168.96.50"}
)

# List snapshots if requested
if ($ListSnapshots) {
    Write-Host "Available snapshots for each VM:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($vm in $VMs) {
        Write-Host "$($vm.Name):" -ForegroundColor Cyan
        $snapshots = VBoxManage snapshot $vm.Name list --machinereadable 2>&1

        if ($LASTEXITCODE -eq 0) {
            $snapshots | Select-String 'SnapshotName.*="([^"]+)"' | ForEach-Object {
                if ($_ -match 'SnapshotName.*="([^"]+)"') {
                    Write-Host "  - $($matches[1])" -ForegroundColor White
                }
            }
        } else {
            Write-Host "  No snapshots found" -ForegroundColor Gray
        }
        Write-Host ""
    }
    exit 0
}

# Determine snapshot to restore
if ($Latest) {
    # Find latest snapshot from mcorp-dc
    $snapshots = VBoxManage snapshot mcorp-dc list --machinereadable 2>&1 | Select-String 'SnapshotName.*="([^"]+)"'

    if ($snapshots) {
        $latestSnapshot = $snapshots | Select-Object -Last 1
        if ($latestSnapshot -match 'SnapshotName.*="([^"]+)"') {
            $SnapshotName = $matches[1]
            Write-Host "Latest snapshot detected: $SnapshotName" -ForegroundColor Yellow
        }
    }
}

if ([string]::IsNullOrEmpty($SnapshotName)) {
    Write-Host "ERROR: No snapshot specified!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\Restore-CRTPLab.ps1 -SnapshotName 'CRTP-Snapshot-2024-01-24_12-30-00'" -ForegroundColor White
    Write-Host "  .\Restore-CRTPLab.ps1 -Latest" -ForegroundColor White
    Write-Host "  .\Restore-CRTPLab.ps1 -ListSnapshots" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Restoring to snapshot: $SnapshotName" -ForegroundColor Yellow
Write-Host ""

# Confirm
Write-Host "WARNING: This will revert all VMs to the snapshot state." -ForegroundColor Yellow
Write-Host "Any changes made after the snapshot will be LOST!" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Type 'YES' to continue"

if ($confirmation -ne "YES") {
    Write-Host "Restore cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# First, shutdown all running VMs
Write-Host "[STEP 1] Shutting down running VMs..." -ForegroundColor Yellow
Write-Host ""

foreach ($vm in $VMs) {
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "Shutting down $($vm.Name)..." -ForegroundColor White
        VBoxManage controlvm $vm.Name poweroff 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
}

Write-Host "Waiting for VMs to fully stop..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Restore snapshots
Write-Host ""
Write-Host "[STEP 2] Restoring snapshots..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($vm in $VMs) {
    Write-Host "Restoring $($vm.Name) to '$SnapshotName'..." -ForegroundColor White

    $result = VBoxManage snapshot $vm.Name restore $SnapshotName 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  FAILED: $result" -ForegroundColor Red
        $failCount++
    }
}

# Results
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESTORE RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Successfully restored: $successCount / $($VMs.Count)" -ForegroundColor Green
Write-Host "Failed to restore: $failCount / $($VMs.Count)" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($successCount -eq $VMs.Count) {
    Write-Host "All VMs restored successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Start the lab: .\Start-CRTPLab.ps1" -ForegroundColor White
    Write-Host "  2. Test connectivity: .\Test-CRTPLab.ps1" -ForegroundColor White
} else {
    Write-Host "Some VMs failed to restore. Check errors above." -ForegroundColor Yellow
}

Write-Host ""
