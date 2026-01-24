# ========================================
# SNAPSHOT CRTP LAB ENVIRONMENT
# Takes snapshots of all 10 VMs
# ========================================

param(
    [string]$SnapshotName = "",  # Custom snapshot name
    [string]$Description = "CRTP Lab snapshot"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SNAPSHOT CRTP LAB ENVIRONMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate snapshot name with timestamp if not provided
if ([string]::IsNullOrEmpty($SnapshotName)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $SnapshotName = "CRTP-Snapshot-$timestamp"
}

Write-Host "Snapshot Name: $SnapshotName" -ForegroundColor Yellow
Write-Host "Description: $Description" -ForegroundColor Yellow
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

$successCount = 0
$failCount = 0

foreach ($vm in $VMs) {
    Write-Host "Creating snapshot for $($vm.Name)..." -ForegroundColor White

    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    # Take snapshot (works whether VM is running or stopped)
    $result = VBoxManage snapshot $vm.Name take $SnapshotName --description $Description 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  FAILED: $result" -ForegroundColor Red
        $failCount++
    }
}

# Show snapshot list for first VM as example
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Successful snapshots: $successCount / $($VMs.Count)" -ForegroundColor Green
Write-Host "Failed snapshots: $failCount / $($VMs.Count)" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($successCount -eq $VMs.Count) {
    Write-Host "All snapshots created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Snapshot name: $SnapshotName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To restore this snapshot later, run:" -ForegroundColor Yellow
    Write-Host "  .\Restore-CRTPLab.ps1 -SnapshotName '$SnapshotName'" -ForegroundColor White
} else {
    Write-Host "Some snapshots failed. Check errors above." -ForegroundColor Yellow
}

Write-Host ""

# List snapshots for mcorp-dc as example
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SNAPSHOTS FOR MCORP-DC (example)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
VBoxManage snapshot mcorp-dc list --machinereadable 2>&1 | Select-String "SnapshotName" | ForEach-Object {
    $_ -replace 'SnapshotName.*="([^"]+)"', '  - $1'
}
Write-Host ""
