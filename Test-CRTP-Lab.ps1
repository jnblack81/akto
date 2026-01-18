# ========================================
# CRTP LAB COMPREHENSIVE VERIFICATION
# Tests actual cross-forest functionality
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB COMPREHENSIVE TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tests = @()
$passed = 0
$failed = 0

# Determine current domain
$currentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
$hostname = $env:COMPUTERNAME

Write-Host "Running on: $hostname" -ForegroundColor Yellow
Write-Host "Domain: $currentDomain" -ForegroundColor Yellow
Write-Host ""

# Test 1: Trust Objects Exist
Write-Host "[TEST 1/10] Checking trust objects..." -ForegroundColor Cyan
try {
    if ($currentDomain -like "*moneycorp*") {
        $trustCheck = nltest /server:mcorp-dc /domain_trusts 2>&1 | Select-String "eurocorp"
        if ($trustCheck) {
            Write-Host "  PASS: eurocorp trust found" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL: eurocorp trust NOT found" -ForegroundColor Red
            $failed++
        }
    } elseif ($currentDomain -like "*eurocorp*") {
        $trustCheck = nltest /domain_trusts 2>&1 | Select-String "moneycorp"
        if ($trustCheck) {
            Write-Host "  PASS: moneycorp trust found" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAIL: moneycorp trust NOT found" -ForegroundColor Red
            $failed++
        }
    }
} catch {
    Write-Host "  FAIL: Error checking trusts - $_" -ForegroundColor Red
    $failed++
}

# Test 2: DNS Resolution - eurocorp
Write-Host ""
Write-Host "[TEST 2/10] DNS resolution - ecorp-dc.eurocorp.local" -ForegroundColor Cyan
try {
    $dns = Resolve-DnsName ecorp-dc.eurocorp.local -ErrorAction Stop
    if ($dns.IPAddress) {
        Write-Host "  PASS: Resolves to $($dns.IPAddress)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL: No IP address returned" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Cannot resolve - $_" -ForegroundColor Red
    $failed++
}

# Test 3: DNS Resolution - moneycorp
Write-Host ""
Write-Host "[TEST 3/10] DNS resolution - mcorp-dc.moneycorp.local" -ForegroundColor Cyan
try {
    $dns = Resolve-DnsName mcorp-dc.moneycorp.local -ErrorAction Stop
    if ($dns.IPAddress) {
        Write-Host "  PASS: Resolves to $($dns.IPAddress)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL: No IP address returned" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Cannot resolve - $_" -ForegroundColor Red
    $failed++
}

# Test 4: Network connectivity - eurocorp
Write-Host ""
Write-Host "[TEST 4/10] Network connectivity to ecorp-dc (192.168.96.11)" -ForegroundColor Cyan
try {
    $ping = Test-Connection -ComputerName 192.168.96.11 -Count 2 -Quiet
    if ($ping) {
        Write-Host "  PASS: Can ping ecorp-dc" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL: Cannot ping ecorp-dc" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Error pinging - $_" -ForegroundColor Red
    $failed++
}

# Test 5: Network connectivity - moneycorp
Write-Host ""
Write-Host "[TEST 5/10] Network connectivity to mcorp-dc (192.168.96.10)" -ForegroundColor Cyan
try {
    $ping = Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet
    if ($ping) {
        Write-Host "  PASS: Can ping mcorp-dc" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL: Cannot ping mcorp-dc" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Error pinging - $_" -ForegroundColor Red
    $failed++
}

# Test 6: Query eurocorp domain
Write-Host ""
Write-Host "[TEST 6/10] Cross-forest query - eurocorp.local domain" -ForegroundColor Cyan
try {
    $domain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'eurocorp.local'))))
    if ($domain.Name -eq "eurocorp.local") {
        Write-Host "  PASS: Successfully queried eurocorp.local" -ForegroundColor Green
        Write-Host "    Domain: $($domain.Name)" -ForegroundColor Gray
        Write-Host "    Forest: $($domain.Forest)" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "  FAIL: Query returned wrong domain" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Cannot query eurocorp.local - $_" -ForegroundColor Red
    $failed++
}

# Test 7: Query moneycorp domain
Write-Host ""
Write-Host "[TEST 7/10] Cross-forest query - moneycorp.local domain" -ForegroundColor Cyan
try {
    $domain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'moneycorp.local'))))
    if ($domain.Name -eq "moneycorp.local") {
        Write-Host "  PASS: Successfully queried moneycorp.local" -ForegroundColor Green
        Write-Host "    Domain: $($domain.Name)" -ForegroundColor Gray
        Write-Host "    Forest: $($domain.Forest)" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "  FAIL: Query returned wrong domain" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Cannot query moneycorp.local - $_" -ForegroundColor Red
    $failed++
}

# Test 8: Enumerate eurocorp users
Write-Host ""
Write-Host "[TEST 8/10] Enumerate users in eurocorp.local" -ForegroundColor Cyan
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://eurocorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 10
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "  PASS: Found $($results.Count) users in eurocorp.local" -ForegroundColor Green
        $results | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $($_.Properties.samaccountname)" -ForegroundColor Gray
        }
        $passed++
    } else {
        Write-Host "  WARN: No users found (domain may be empty)" -ForegroundColor Yellow
        $passed++
    }
} catch {
    Write-Host "  FAIL: Cannot enumerate users - $_" -ForegroundColor Red
    $failed++
}

# Test 9: Enumerate moneycorp users
Write-Host ""
Write-Host "[TEST 9/10] Enumerate users in moneycorp.local" -ForegroundColor Cyan
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 10
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "  PASS: Found $($results.Count) users in moneycorp.local" -ForegroundColor Green
        $results | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $($_.Properties.samaccountname)" -ForegroundColor Gray
        }
        $passed++
    } else {
        Write-Host "  WARN: No users found (domain may be empty)" -ForegroundColor Yellow
        $passed++
    }
} catch {
    Write-Host "  FAIL: Cannot enumerate users - $_" -ForegroundColor Red
    $failed++
}

# Test 10: Verify trust attributes
Write-Host ""
Write-Host "[TEST 10/10] Verify forest trust attributes" -ForegroundColor Cyan
try {
    $nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
    if ($nltest -match "eurocorp.*foresttrans") {
        Write-Host "  PASS: Forest transitive attribute confirmed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL: Forest transitive attribute NOT found" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL: Cannot verify attributes - $_" -ForegroundColor Red
    $failed++
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: 10" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "STATUS: ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "CRTP Lab is fully functional and ready for use!" -ForegroundColor Green
} elseif ($passed -ge 7) {
    Write-Host "STATUS: MOSTLY WORKING" -ForegroundColor Yellow
    Write-Host "Lab is functional but has some issues. Review failed tests above." -ForegroundColor Yellow
} else {
    Write-Host "STATUS: CONFIGURATION INCOMPLETE" -ForegroundColor Red
    Write-Host "Critical issues found. Lab may not work correctly." -ForegroundColor Red
}

Write-Host ""
