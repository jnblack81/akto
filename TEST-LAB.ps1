# CRTP LAB COMPLETE VERIFICATION
# Run on any DC to verify everything works

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB COMPLETE VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$hostname = $env:COMPUTERNAME
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
Write-Host "Machine: $hostname" -ForegroundColor Yellow
Write-Host "Domain: $domain" -ForegroundColor Yellow
Write-Host ""

$passed = 0
$failed = 0

# Test 1: DNS - mcorp-dc
Write-Host "[1/15] DNS: mcorp-dc.moneycorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName mcorp-dc.moneycorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.10") {
        Write-Host "  PASS - Resolves to 192.168.96.10" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong IP: $($dns.IPAddress)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot resolve" -ForegroundColor Red
    $failed++
}

# Test 2: DNS - ecorp-dc
Write-Host "[2/15] DNS: ecorp-dc.eurocorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName ecorp-dc.eurocorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.11") {
        Write-Host "  PASS - Resolves to 192.168.96.11" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong IP: $($dns.IPAddress)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot resolve" -ForegroundColor Red
    $failed++
}

# Test 3: DNS - dcorp-dc
Write-Host "[3/15] DNS: dcorp-dc.dollarcorp.moneycorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName dcorp-dc.dollarcorp.moneycorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.12") {
        Write-Host "  PASS - Resolves to 192.168.96.12" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong IP: $($dns.IPAddress)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot resolve" -ForegroundColor Red
    $failed++
}

# Test 4: Ping mcorp-dc
Write-Host "[4/15] Ping: mcorp-dc (192.168.96.10)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet) {
    Write-Host "  PASS - Can ping mcorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - Cannot ping" -ForegroundColor Red
    $failed++
}

# Test 5: Ping ecorp-dc
Write-Host "[5/15] Ping: ecorp-dc (192.168.96.11)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.11 -Count 2 -Quiet) {
    Write-Host "  PASS - Can ping ecorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - Cannot ping" -ForegroundColor Red
    $failed++
}

# Test 6: Ping dcorp-dc
Write-Host "[6/15] Ping: dcorp-dc (192.168.96.12)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.12 -Count 2 -Quiet) {
    Write-Host "  PASS - Can ping dcorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - Cannot ping" -ForegroundColor Red
    $failed++
}

# Test 7: mcorp trusts
Write-Host "[7/15] Trust: mcorp-dc has eurocorp trust" -ForegroundColor White
$nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
if ($nltest -match "eurocorp") {
    Write-Host "  PASS - Trust to eurocorp exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - No trust to eurocorp" -ForegroundColor Red
    $failed++
}

# Test 8: ecorp trusts
Write-Host "[8/15] Trust: ecorp-dc has moneycorp trust" -ForegroundColor White
$nltest = nltest /server:ecorp-dc /domain_trusts 2>&1 | Out-String
if ($nltest -match "moneycorp") {
    Write-Host "  PASS - Trust to moneycorp exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - No trust to moneycorp" -ForegroundColor Red
    $failed++
}

# Test 9: Bidirectional
Write-Host "[9/15] Trust: Bidirectional verification" -ForegroundColor White
$mcorpOK = (nltest /server:mcorp-dc /domain_trusts 2>&1 | Select-String "eurocorp") -ne $null
$ecorpOK = (nltest /server:ecorp-dc /domain_trusts 2>&1 | Select-String "moneycorp") -ne $null
if ($mcorpOK -and $ecorpOK) {
    Write-Host "  PASS - Bidirectional trust confirmed" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL - Trust not bidirectional" -ForegroundColor Red
    $failed++
}

# Test 10: Query moneycorp
Write-Host "[10/15] Query: moneycorp.local domain" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','moneycorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "moneycorp.local") {
        Write-Host "  PASS - Successfully queried moneycorp.local" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong domain returned" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot query moneycorp.local" -ForegroundColor Red
    $failed++
}

# Test 11: Query eurocorp
Write-Host "[11/15] Query: eurocorp.local domain" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','eurocorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "eurocorp.local") {
        Write-Host "  PASS - Successfully queried eurocorp.local" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong domain returned" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot query eurocorp.local" -ForegroundColor Red
    $failed++
}

# Test 12: Query dcorp
Write-Host "[12/15] Query: dollarcorp.moneycorp.local domain" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','dollarcorp.moneycorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "dollarcorp.moneycorp.local") {
        Write-Host "  PASS - Successfully queried dollarcorp.moneycorp.local" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL - Wrong domain returned" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL - Cannot query dollarcorp" -ForegroundColor Red
    $failed++
}

# Test 13: Enumerate moneycorp users
Write-Host "[13/15] Users: moneycorp.local enumeration" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()
    Write-Host "  PASS - Found $($results.Count) users" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  FAIL - Cannot enumerate users" -ForegroundColor Red
    $failed++
}

# Test 14: Enumerate eurocorp users
Write-Host "[14/15] Users: eurocorp.local enumeration" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://eurocorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()
    Write-Host "  PASS - Found $($results.Count) users" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  FAIL - Cannot enumerate users" -ForegroundColor Red
    $failed++
}

# Test 15: Enumerate dcorp users
Write-Host "[15/15] Users: dollarcorp.moneycorp.local enumeration" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dollarcorp.moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()
    Write-Host "  PASS - Found $($results.Count) users" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  FAIL - Cannot enumerate users" -ForegroundColor Red
    $failed++
}

# Results
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $passed / 15" -ForegroundColor Green
Write-Host "Failed: $failed / 15" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "ALL TESTS PASSED - LAB IS READY" -ForegroundColor Green
} elseif ($failed -le 2) {
    Write-Host "MOSTLY WORKING - Minor issues" -ForegroundColor Yellow
} else {
    Write-Host "CRITICAL FAILURES - Lab not ready" -ForegroundColor Red
}
Write-Host ""
