# ========================================
# TEST CRTP LAB
# Tests VM status and RDP access
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB STATUS TEST" -ForegroundColor Cyan
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

$totalTests = 0
$passedTests = 0

Write-Host "[1/2] Testing VM Status" -ForegroundColor Yellow
Write-Host ""

foreach ($vm in $VMs) {
    $totalTests++
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "[PASS] $($vm.Name.PadRight(20)) ($($vm.IP)) - Running" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "[FAIL] $($vm.Name.PadRight(20)) ($($vm.IP)) - Not running" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[2/2] Testing RDP Access to Student Workstation" -ForegroundColor Yellow
Write-Host ""

$totalTests++
Write-Host "Testing RDP to dcorp-stdadmin (192.168.96.50:3389)... " -NoNewline

$rdpTest = Test-NetConnection -ComputerName 192.168.96.50 -Port 3389 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

if ($rdpTest.TcpTestSucceeded) {
    Write-Host "[PASS]" -ForegroundColor Green
    $passedTests++
} else {
    Write-Host "[FAIL]" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Passed: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host ""

if ($passedTests -eq $totalTests) {
    Write-Host "ALL TESTS PASSED - LAB IS READY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access the lab:" -ForegroundColor Yellow
    Write-Host "  1. RDP to dcorp-stdadmin (192.168.96.50)" -ForegroundColor White
    Write-Host "  2. Login as dollarcorp\student : Password123!" -ForegroundColor White
    Write-Host "  3. Run attacks from there" -ForegroundColor White
} else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Start missing VMs: .\Start-CRTPLab.ps1" -ForegroundColor White
    Write-Host "  - Check VirtualBox for errors" -ForegroundColor White
}
Write-Host ""
