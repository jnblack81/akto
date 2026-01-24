# ========================================
# TEST CRTP LAB CONNECTIVITY
# Tests network connectivity and basic services
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB CONNECTIVITY TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# All VMs with their expected IPs and roles
$VMs = @(
    @{Name="mcorp-dc"; IP="192.168.96.10"; Role="Domain Controller"; Ports=@(53,88,389,445)},
    @{Name="ecorp-dc"; IP="192.168.96.100"; Role="Domain Controller"; Ports=@(53,88,389,445)},
    @{Name="dcorp-dc"; IP="192.168.96.20"; Role="Domain Controller"; Ports=@(53,88,389,445)},
    @{Name="dcorp-adminsrv"; IP="192.168.96.21"; Role="Admin Server"; Ports=@(445,3389)},
    @{Name="dcorp-appsrv"; IP="192.168.96.22"; Role="App Server"; Ports=@(80,443,445)},
    @{Name="dcorp-ci"; IP="192.168.96.23"; Role="CI Server"; Ports=@(445,8080)},
    @{Name="dcorp-mgmt"; IP="192.168.96.24"; Role="Management Server"; Ports=@(445,3389)},
    @{Name="dcorp-mssql"; IP="192.168.96.25"; Role="SQL Server"; Ports=@(445,1433)},
    @{Name="dcorp-sql1"; IP="192.168.96.26"; Role="SQL Server"; Ports=@(445,1433)},
    @{Name="dcorp-stdadmin"; IP="192.168.96.50"; Role="Student Workstation"; Ports=@(445,3389)}
)

$totalTests = 0
$passedTests = 0
$failedTests = 0

Write-Host "[PHASE 1] Testing VM Status" -ForegroundColor Yellow
Write-Host ""

foreach ($vm in $VMs) {
    $totalTests++
    $status = VBoxManage showvminfo $vm.Name --machinereadable 2>&1 | Select-String "VMState="

    if ($status -match 'VMState="running"') {
        Write-Host "[PASS] $($vm.Name.PadRight(20)) - Running" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "[FAIL] $($vm.Name.PadRight(20)) - Not running" -ForegroundColor Red
        $failedTests++
    }
}

Write-Host ""
Write-Host "[PHASE 2] Testing Critical Services (Ports)" -ForegroundColor Yellow
Write-Host "NOTE: Ping/ICMP is disabled on Windows VMs by default - this is normal" -ForegroundColor Gray
Write-Host ""

foreach ($vm in $VMs) {
    Write-Host "$($vm.Name) ($($vm.Role)):" -ForegroundColor White

    foreach ($port in $vm.Ports) {
        $totalTests++
        Write-Host "  Port $port... " -NoNewline

        $result = Test-NetConnection -ComputerName $vm.IP -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

        if ($result.TcpTestSucceeded) {
            Write-Host "[PASS]" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[FAIL]" -ForegroundColor Red
            $failedTests++
        }
    }
}

Write-Host ""
Write-Host "[PHASE 3] Testing DNS Resolution" -ForegroundColor Yellow
Write-Host ""

$dnsTests = @(
    @{Query="mcorp-dc.moneycorp.local"; ExpectedIP="192.168.96.10"},
    @{Query="ecorp-dc.eurocorp.local"; ExpectedIP="192.168.96.100"},
    @{Query="dcorp-dc.dcorp.moneycorp.local"; ExpectedIP="192.168.96.20"},
    @{Query="moneycorp.local"; Type="SOA"},
    @{Query="eurocorp.local"; Type="SOA"},
    @{Query="dcorp.moneycorp.local"; Type="SOA"}
)

foreach ($test in $dnsTests) {
    $totalTests++
    Write-Host "Resolving $($test.Query)... " -NoNewline

    try {
        if ($test.Type -eq "SOA") {
            $result = Resolve-DnsName -Name $test.Query -Type SOA -ErrorAction Stop
        } else {
            $result = Resolve-DnsName -Name $test.Query -ErrorAction Stop
        }

        if ($result) {
            Write-Host "[PASS]" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[FAIL]" -ForegroundColor Red
            $failedTests++
        }
    } catch {
        Write-Host "[FAIL]" -ForegroundColor Red
        $failedTests++
    }
}

Write-Host ""
Write-Host "[PHASE 4] Testing Forest Trust" -ForegroundColor Yellow
Write-Host ""

$totalTests++
Write-Host "Testing moneycorp <-> eurocorp trust... " -NoNewline

$nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
if ($nltest -match "eurocorp") {
    Write-Host "[PASS]" -ForegroundColor Green
    $passedTests++
} else {
    Write-Host "[FAIL]" -ForegroundColor Red
    $failedTests++
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host ""

$percentage = [math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 80) { "Yellow" } else { "Red" })
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "ALL TESTS PASSED - LAB IS READY!" -ForegroundColor Green
} else {
    Write-Host "SOME TESTS FAILED - Review above for details" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  1. Ensure all VMs are running: .\Start-CRTPLab.ps1" -ForegroundColor White
    Write-Host "  2. Run FIX-AND-TEST.ps1 on each DC inside the VM" -ForegroundColor White
    Write-Host "  3. Check VM network adapters are on correct network" -ForegroundColor White
}
Write-Host ""
