# ========================================
# CRTP LAB AUTO-FIX AND VERIFY
# Automatically fixes IP addresses and tests everything
# Run on each DC - it detects and fixes issues
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP LAB AUTO-FIX AND VERIFY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$hostname = $env:COMPUTERNAME
$domain = (Get-WmiObject Win32_ComputerSystem).Domain

Write-Host "Machine: $hostname" -ForegroundColor Yellow
Write-Host "Domain: $domain" -ForegroundColor Yellow
Write-Host ""

# Expected IPs
$expectedIPs = @{
    "MCORP-DC" = "192.168.96.10"
    "ECORP-DC" = "192.168.96.100"
    "DCORP-DC" = "192.168.96.20"
    "DCORP-ADMINSRV" = "192.168.96.21"
    "DCORP-APPSRV" = "192.168.96.22"
    "DCORP-CI" = "192.168.96.23"
    "DCORP-MGMT" = "192.168.96.24"
    "DCORP-MSSQL" = "192.168.96.25"
    "DCORP-SQL1" = "192.168.96.26"
    "DCORP-STDADMIN" = "192.168.96.50"
}

$expectedIP = $expectedIPs[$hostname]

if (-not $expectedIP) {
    Write-Host "Unknown machine: $hostname" -ForegroundColor Red
    Write-Host "Expected: MCORP-DC, ECORP-DC, DCORP-DC, or DCORP-* member servers" -ForegroundColor Red
    exit 1
}

Write-Host "Expected IP for this machine: $expectedIP" -ForegroundColor Cyan
Write-Host ""

# Get current IP
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$currentIP = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress

Write-Host "Current IP: $currentIP" -ForegroundColor Yellow

if ($currentIP -ne $expectedIP) {
    Write-Host "IP ADDRESS MISMATCH - FIXING..." -ForegroundColor Red
    Write-Host ""

    # Remove all existing IPs on this adapter
    Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | ForEach-Object {
        Write-Host "Removing IP: $($_.IPAddress)" -ForegroundColor Yellow
        Remove-NetIPAddress -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
    }

    # Add correct IP
    Write-Host "Adding correct IP: $expectedIP" -ForegroundColor Green
    try {
        New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $expectedIP -PrefixLength 24 -ErrorAction Stop | Out-Null
        Write-Host "IP address set successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error setting IP: $_" -ForegroundColor Red
    }

    # Set DNS based on machine
    Write-Host "Configuring DNS..." -ForegroundColor Yellow
    switch ($hostname) {
        "MCORP-DC" {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "127.0.0.1","192.168.96.10"
        }
        "ECORP-DC" {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "127.0.0.1","192.168.96.100"
        }
        "DCORP-DC" {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "127.0.0.1","192.168.96.20","192.168.96.10"
        }
        default {
            # All member servers point to dcorp-dc then mcorp-dc
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "192.168.96.20","192.168.96.10"
        }
    }

    Write-Host "Restarting network adapter..." -ForegroundColor Yellow
    Restart-NetAdapter -Name $adapter.Name
    Start-Sleep -Seconds 5

    # Update DNS A record
    if (Get-Command Register-DnsClient -ErrorAction SilentlyContinue) {
        Write-Host "Registering DNS..." -ForegroundColor Yellow
        Register-DnsClient
    }

    Write-Host ""
    Write-Host "IP FIXED! Verifying..." -ForegroundColor Green
    ipconfig | Select-String "IPv4"
    Write-Host ""

} else {
    Write-Host "IP address is correct!" -ForegroundColor Green
    Write-Host ""
}

# Configure auto-logon for student workstation
if ($hostname -eq "DCORP-STDADMIN") {
    Write-Host "Configuring auto-logon for student account..." -ForegroundColor Yellow

    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    try {
        Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1" -Type String -ErrorAction Stop
        Set-ItemProperty -Path $RegPath -Name "DefaultUserName" -Value "student" -Type String -ErrorAction Stop
        Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "Password123!" -Type String -ErrorAction Stop
        Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value "dollarcorp" -Type String -ErrorAction Stop

        # Disable legal notice
        $LegalNoticePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if (Test-Path $LegalNoticePath) {
            Set-ItemProperty -Path $LegalNoticePath -Name "legalnoticecaption" -Value "" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $LegalNoticePath -Name "legalnoticetext" -Value "" -ErrorAction SilentlyContinue
        }

        Write-Host "  Auto-logon configured for dollarcorp\student" -ForegroundColor Green
        Write-Host "  Next boot will automatically log in" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to configure auto-logon: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Configure DNS forwarders (critical for cross-forest queries)
if ($hostname -eq "MCORP-DC") {
    Write-Host "Configuring DNS forwarders for mcorp-dc..." -ForegroundColor Yellow

    # Check if eurocorp.local forwarder exists
    $existingForwarder = Get-DnsServerZone -Name "eurocorp.local" -ErrorAction SilentlyContinue

    if ($existingForwarder) {
        # Check if it has the correct IP
        $masterServers = $existingForwarder.MasterServers
        if ($masterServers -notcontains "192.168.96.100") {
            Write-Host "  Fixing eurocorp.local forwarder (wrong IP: $masterServers)" -ForegroundColor Yellow
            Remove-DnsServerZone -Name "eurocorp.local" -Force -ErrorAction SilentlyContinue
            Add-DnsServerConditionalForwarderZone -Name "eurocorp.local" -MasterServers 192.168.96.100
            Write-Host "  eurocorp.local forwarder configured to 192.168.96.100" -ForegroundColor Green
        } else {
            Write-Host "  eurocorp.local forwarder already correct" -ForegroundColor Green
        }
    } else {
        Write-Host "  Adding eurocorp.local forwarder to 192.168.96.100" -ForegroundColor Yellow
        Add-DnsServerConditionalForwarderZone -Name "eurocorp.local" -MasterServers 192.168.96.100
        Write-Host "  eurocorp.local forwarder configured" -ForegroundColor Green
    }
    Write-Host ""
}

if ($hostname -eq "ECORP-DC") {
    Write-Host "Configuring DNS forwarders for ecorp-dc..." -ForegroundColor Yellow

    # Check if moneycorp.local forwarder exists
    $existingForwarder = Get-DnsServerZone -Name "moneycorp.local" -ErrorAction SilentlyContinue

    if ($existingForwarder -and $existingForwarder.ZoneType -eq "Forwarder") {
        # Check if it has the correct IP
        $masterServers = $existingForwarder.MasterServers
        if ($masterServers -notcontains "192.168.96.10") {
            Write-Host "  Fixing moneycorp.local forwarder (wrong IP: $masterServers)" -ForegroundColor Yellow
            Remove-DnsServerZone -Name "moneycorp.local" -Force -ErrorAction SilentlyContinue
            Add-DnsServerConditionalForwarderZone -Name "moneycorp.local" -MasterServers 192.168.96.10
            Write-Host "  moneycorp.local forwarder configured to 192.168.96.10" -ForegroundColor Green
        } else {
            Write-Host "  moneycorp.local forwarder already correct" -ForegroundColor Green
        }
    } elseif (-not $existingForwarder) {
        Write-Host "  Adding moneycorp.local forwarder to 192.168.96.10" -ForegroundColor Yellow
        Add-DnsServerConditionalForwarderZone -Name "moneycorp.local" -MasterServers 192.168.96.10
        Write-Host "  moneycorp.local forwarder configured" -ForegroundColor Green
    }
    Write-Host ""
}

if ($hostname -eq "DCORP-DC") {
    Write-Host "Configuring DNS forwarders for dcorp-dc..." -ForegroundColor Yellow

    # Check if eurocorp.local forwarder exists
    $existingForwarder = Get-DnsServerZone -Name "eurocorp.local" -ErrorAction SilentlyContinue

    if ($existingForwarder) {
        # Check if it has the correct IP
        $masterServers = $existingForwarder.MasterServers
        if ($masterServers -notcontains "192.168.96.100") {
            Write-Host "  Fixing eurocorp.local forwarder (wrong IP: $masterServers)" -ForegroundColor Yellow
            Remove-DnsServerZone -Name "eurocorp.local" -Force -ErrorAction SilentlyContinue
            Add-DnsServerConditionalForwarderZone -Name "eurocorp.local" -MasterServers 192.168.96.100
            Write-Host "  eurocorp.local forwarder configured to 192.168.96.100" -ForegroundColor Green
        } else {
            Write-Host "  eurocorp.local forwarder already correct" -ForegroundColor Green
        }
    } else {
        Write-Host "  Adding eurocorp.local forwarder to 192.168.96.100" -ForegroundColor Yellow
        Add-DnsServerConditionalForwarderZone -Name "eurocorp.local" -MasterServers 192.168.96.100
        Write-Host "  eurocorp.local forwarder configured" -ForegroundColor Green
    }
    Write-Host ""
}

# Run tests
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RUNNING VERIFICATION TESTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Ping mcorp-dc
Write-Host "[1/9] Ping mcorp-dc (192.168.96.10)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet) {
    Write-Host "  PASS" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 2: Ping ecorp-dc
Write-Host "[2/9] Ping ecorp-dc (192.168.96.100)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.100 -Count 2 -Quiet) {
    Write-Host "  PASS" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 3: Ping dcorp-dc
Write-Host "[3/9] Ping dcorp-dc (192.168.96.20)" -ForegroundColor White
if (Test-Connection -ComputerName 192.168.96.20 -Count 2 -Quiet) {
    Write-Host "  PASS" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 4: Query moneycorp
Write-Host "[4/9] Query moneycorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','moneycorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "moneycorp.local") {
        Write-Host "  PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 5: Query eurocorp
Write-Host "[5/9] Query eurocorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','eurocorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "eurocorp.local") {
        Write-Host "  PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 6: Query dcorp
Write-Host "[6/9] Query dcorp.moneycorp.local" -ForegroundColor White
try {
    $ctx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain','dcorp.moneycorp.local')
    $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
    if ($dom.Name -eq "dcorp.moneycorp.local") {
        Write-Host "  PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 7: Forest trust check
Write-Host "[7/9] Forest trust moneycorp<->eurocorp" -ForegroundColor White
$nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
if ($nltest -match "eurocorp") {
    Write-Host "  PASS" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 8: Enumerate moneycorp users
Write-Host "[8/9] Enumerate moneycorp.local users" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://moneycorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()
    Write-Host "  PASS - Found $($results.Count) users" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Test 9: Enumerate eurocorp users
Write-Host "[9/9] Enumerate eurocorp.local users" -ForegroundColor White
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://eurocorp.local")
    $searcher.Filter = "(objectClass=user)"
    $searcher.PageSize = 100
    $results = $searcher.FindAll()
    Write-Host "  PASS - Found $($results.Count) users" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  FAIL" -ForegroundColor Red
    $failed++
}

# Results
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $passed / 9" -ForegroundColor Green
Write-Host "Failed: $failed / 9" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "ALL TESTS PASSED - $hostname IS READY" -ForegroundColor Green
} else {
    Write-Host "SOME FAILURES - Review above" -ForegroundColor Yellow
}
Write-Host ""
