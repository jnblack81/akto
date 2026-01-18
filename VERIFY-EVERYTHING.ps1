# ========================================
# COMPLETE CRTP LAB VERIFICATION
# Tests EVERYTHING - No assumptions
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CRTP LAB COMPLETE VERIFICATION - TESTING EVERYTHING      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$hostname = $env:COMPUTERNAME
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
$whoami = whoami

Write-Host "Machine: $hostname" -ForegroundColor Yellow
Write-Host "Domain: $domain" -ForegroundColor Yellow
Write-Host "User: $whoami" -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

$passed = 0
$failed = 0
$warnings = 0

# ========================================
# CATEGORY 1: BASIC INFRASTRUCTURE
# ========================================

Write-Host "CATEGORY 1: BASIC INFRASTRUCTURE" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Test 1.1: DNS - mcorp-dc
Write-Host "[1.1] DNS Resolution: mcorp-dc.moneycorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName mcorp-dc.moneycorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.10") {
        Write-Host "      ✓ PASS - Resolves to 192.168.96.10" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Resolves to $($dns.IPAddress) (expected 192.168.96.10)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot resolve: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 1.2: DNS - ecorp-dc
Write-Host "[1.2] DNS Resolution: ecorp-dc.eurocorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName ecorp-dc.eurocorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.11") {
        Write-Host "      ✓ PASS - Resolves to 192.168.96.11" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Resolves to $($dns.IPAddress) (expected 192.168.96.11)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot resolve: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 1.3: DNS - dcorp-dc
Write-Host "[1.3] DNS Resolution: dcorp-dc.dollarcorp.moneycorp.local" -ForegroundColor White
try {
    $dns = Resolve-DnsName dcorp-dc.dollarcorp.moneycorp.local -ErrorAction Stop
    if ($dns.IPAddress -eq "192.168.96.12") {
        Write-Host "      ✓ PASS - Resolves to 192.168.96.12" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Resolves to $($dns.IPAddress) (expected 192.168.96.12)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot resolve: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 1.4: Network - mcorp-dc
Write-Host "[1.4] Network Connectivity: mcorp-dc (192.168.96.10)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet) {
    Write-Host "      ✓ PASS - Can ping mcorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "      ✗ FAIL - Cannot ping mcorp-dc" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 1.5: Network - ecorp-dc
Write-Host "[1.5] Network Connectivity: ecorp-dc (192.168.96.11)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.11 -Count 2 -Quiet) {
    Write-Host "      ✓ PASS - Can ping ecorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "      ✗ FAIL - Cannot ping ecorp-dc" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 1.6: Network - dcorp-dc
Write-Host "[1.6] Network Connectivity: dcorp-dc (192.168.96.12)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.12 -Count 2 -Quiet) {
    Write-Host "      ✓ PASS - Can ping dcorp-dc" -ForegroundColor Green
    $passed++
} else {
    Write-Host "      ✗ FAIL - Cannot ping dcorp-dc" -ForegroundColor Red
    $failed++
}
Write-Host ""

# ========================================
# CATEGORY 2: TRUST RELATIONSHIPS
# ========================================

Write-Host "CATEGORY 2: TRUST RELATIONSHIPS" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Test 2.1: Check mcorp trusts
Write-Host "[2.1] Trust Check: mcorp-dc trusts" -ForegroundColor White
try {
    $nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
    if ($nltest -match "eurocorp\.local") {
        Write-Host "      ✓ PASS - mcorp-dc has trust to eurocorp.local" -ForegroundColor Green
        $passed++
        if ($nltest -match "foresttrans") {
            Write-Host "      ✓ INFO - Forest transitive attribute present" -ForegroundColor Green
        }
    } else {
        Write-Host "      ✗ FAIL - mcorp-dc does NOT have trust to eurocorp.local" -ForegroundColor Red
        Write-Host "      Output: $nltest" -ForegroundColor Gray
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot query mcorp-dc trusts: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 2.2: Check ecorp trusts
Write-Host "[2.2] Trust Check: ecorp-dc trusts" -ForegroundColor White
try {
    $nltest = nltest /server:ecorp-dc /domain_trusts 2>&1 | Out-String
    if ($nltest -match "moneycorp\.local") {
        Write-Host "      ✓ PASS - ecorp-dc has trust to moneycorp.local" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "      ✗ FAIL - ecorp-dc does NOT have trust to moneycorp.local" -ForegroundColor Red
        Write-Host "      Output: $nltest" -ForegroundColor Gray
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot query ecorp-dc trusts: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 2.3: Bidirectional check
Write-Host "[2.3] Bidirectional Trust Verification" -ForegroundColor White
$mcorpHasEurocorp = (nltest /server:mcorp-dc /domain_trusts 2>&1 | Select-String "eurocorp") -ne $null
$eurocorpHasMoneycorp = (nltest /server:ecorp-dc /domain_trusts 2>&1 | Select-String "moneycorp") -ne $null
if ($mcorpHasEurocorp -and $eurocorpHasMoneycorp) {
    Write-Host "      ✓ PASS - Bidirectional trust confirmed (both sides configured)" -ForegroundColor Green
    $passed++
} else {
    Write-Host "      ✗ FAIL - Trust is NOT bidirectional" -ForegroundColor Red
    Write-Host "      mcorp → eurocorp: $mcorpHasEurocorp" -ForegroundColor Gray
    Write-Host "      eurocorp → moneycorp: $eurocorpHasMoneycorp" -ForegroundColor Gray
    $failed++
}
Write-Host ""

# ========================================
# CATEGORY 3: CROSS-FOREST QUERIES
# ========================================

Write-Host "CATEGORY 3: CROSS-FOREST QUERIES (THE REAL TEST)" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Test 3.1: Query moneycorp domain
Write-Host "[3.1] Domain Query: moneycorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'moneycorp.local')
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($domain.Name -eq "moneycorp.local") {
        Write-Host "      ✓ PASS - Successfully queried moneycorp.local" -ForegroundColor Green
        Write-Host "        Domain: $($domain.Name)" -ForegroundColor Gray
        Write-Host "        Forest: $($domain.Forest)" -ForegroundColor Gray
        Write-Host "        DC: $($domain.PdcRoleOwner)" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Query returned wrong domain: $($domain.Name)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot query moneycorp.local: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 3.2: Query eurocorp domain
Write-Host "[3.2] Domain Query: eurocorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'eurocorp.local')
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($domain.Name -eq "eurocorp.local") {
        Write-Host "      ✓ PASS - Successfully queried eurocorp.local" -ForegroundColor Green
        Write-Host "        Domain: $($domain.Name)" -ForegroundColor Gray
        Write-Host "        Forest: $($domain.Forest)" -ForegroundColor Gray
        Write-Host "        DC: $($domain.PdcRoleOwner)" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Query returned wrong domain: $($domain.Name)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot query eurocorp.local: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 3.3: Query dcorp domain
Write-Host "[3.3] Domain Query: dollarcorp.moneycorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'dollarcorp.moneycorp.local')
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($domain.Name -eq "dollarcorp.moneycorp.local") {
        Write-Host "      ✓ PASS - Successfully queried dollarcorp.moneycorp.local" -ForegroundColor Green
        Write-Host "        Domain: $($domain.Name)" -ForegroundColor Gray
        Write-Host "        Forest: $($domain.Forest)" -ForegroundColor Gray
        Write-Host "        DC: $($domain.PdcRoleOwner)" -ForegroundColor Gray
        $passed++
    } else {
        Write-Host "      ✗ FAIL - Query returned wrong domain: $($domain.Name)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot query dollarcorp.moneycorp.local: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# ========================================
# CATEGORY 4: USER ENUMERATION
# ========================================

Write-Host "CATEGORY 4: USER ENUMERATION ACROSS FORESTS" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Test 4.1: Enumerate moneycorp users
Write-Host "[4.1] User Enumeration: moneycorp.local" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "      ✓ PASS - Found $($results.Count) users in moneycorp.local" -ForegroundColor Green
        Write-Host "        Sample users:" -ForegroundColor Gray
        $results | Select-Object -First 5 | ForEach-Object {
            $sam = $_.Properties['samaccountname']
            if ($sam) {
                Write-Host "          - $sam" -ForegroundColor Gray
            }
        }
        $passed++
    } else {
        Write-Host "      ⚠ WARN - No users found (domain may be empty)" -ForegroundColor Yellow
        $warnings++
        $passed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot enumerate users: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 4.2: Enumerate eurocorp users
Write-Host "[4.2] User Enumeration: eurocorp.local" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://eurocorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "      ✓ PASS - Found $($results.Count) users in eurocorp.local" -ForegroundColor Green
        Write-Host "        Sample users:" -ForegroundColor Gray
        $results | Select-Object -First 5 | ForEach-Object {
            $sam = $_.Properties['samaccountname']
            if ($sam) {
                Write-Host "          - $sam" -ForegroundColor Gray
            }
        }
        $passed++
    } else {
        Write-Host "      ⚠ WARN - No users found (domain may be empty)" -ForegroundColor Yellow
        $warnings++
        $passed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot enumerate users: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 4.3: Enumerate dcorp users
Write-Host "[4.3] User Enumeration: dollarcorp.moneycorp.local" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dollarcorp.moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "      ✓ PASS - Found $($results.Count) users in dollarcorp.moneycorp.local" -ForegroundColor Green
        Write-Host "        Sample users:" -ForegroundColor Gray
        $results | Select-Object -First 5 | ForEach-Object {
            $sam = $_.Properties['samaccountname']
            if ($sam) {
                Write-Host "          - $sam" -ForegroundColor Gray
            }
        }
        $passed++
    } else {
        Write-Host "      ⚠ WARN - No users found (domain may be empty)" -ForegroundColor Yellow
        $warnings++
        $passed++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot enumerate users: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# ========================================
# CATEGORY 5: COMPUTER ENUMERATION
# ========================================

Write-Host "CATEGORY 5: COMPUTER ENUMERATION ACROSS FORESTS" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Test 5.1: Enumerate moneycorp computers
Write-Host "[5.1] Computer Enumeration: moneycorp.local" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://moneycorp.local")
    $searcher.Filter = "(objectClass=computer)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "      ✓ PASS - Found $($results.Count) computers in moneycorp.local" -ForegroundColor Green
        Write-Host "        Computers:" -ForegroundColor Gray
        $results | ForEach-Object {
            $cn = $_.Properties['cn']
            if ($cn) {
                Write-Host "          - $cn" -ForegroundColor Gray
            }
        }
        $passed++
    } else {
        Write-Host "      ⚠ WARN - No computers found" -ForegroundColor Yellow
        $warnings++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot enumerate computers: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 5.2: Enumerate eurocorp computers
Write-Host "[5.2] Computer Enumeration: eurocorp.local" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://eurocorp.local")
    $searcher.Filter = "(objectClass=computer)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()

    if ($results.Count -gt 0) {
        Write-Host "      ✓ PASS - Found $($results.Count) computers in eurocorp.local" -ForegroundColor Green
        Write-Host "        Computers:" -ForegroundColor Gray
        $results | ForEach-Object {
            $cn = $_.Properties['cn']
            if ($cn) {
                Write-Host "          - $cn" -ForegroundColor Gray
            }
        }
        $passed++
    } else {
        Write-Host "      ⚠ WARN - No computers found" -ForegroundColor Yellow
        $warnings++
    }
} catch {
    Write-Host "      ✗ FAIL - Cannot enumerate computers: $_" -ForegroundColor Red
    $failed++
}
Write-Host ""

# ========================================
# FINAL RESULTS
# ========================================

$total = $passed + $failed
$percentage = [math]::Round(($passed / $total) * 100, 1)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    FINAL RESULTS                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests:    $total" -ForegroundColor White
Write-Host "Passed:         $passed" -ForegroundColor Green
Write-Host "Failed:         $failed" -ForegroundColor Red
Write-Host "Warnings:       $warnings" -ForegroundColor Yellow
Write-Host "Success Rate:   $percentage%" -ForegroundColor $(if($percentage -ge 90){"Green"}elseif($percentage -ge 70){"Yellow"}else{"Red"})
Write-Host ""

if ($failed -eq 0) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          ✓✓✓ ALL TESTS PASSED ✓✓✓                         ║" -ForegroundColor Green
    Write-Host "║   CRTP LAB IS FULLY FUNCTIONAL AND READY FOR USE!         ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
} elseif ($failed -le 2) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║        ⚠ LAB IS MOSTLY WORKING ⚠                           ║" -ForegroundColor Yellow
    Write-Host "║   Minor issues found - review failed tests above           ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
} else {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║          ✗✗✗ CRITICAL FAILURES ✗✗✗                        ║" -ForegroundColor Red
    Write-Host "║   LAB CONFIGURATION IS INCOMPLETE - REQUIRES FIXES         ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

Write-Host ""
