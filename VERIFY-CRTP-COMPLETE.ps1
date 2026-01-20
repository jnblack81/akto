# ========================================
# CRTP LAB - COMPLETE VERIFICATION
# Verifies ALL requirements for CRTP labs
# Run on dcorp-stdadmin (student workstation)
# ========================================

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
$testNum = 1

# Test function
function Test-Item {
    param($Name, $ScriptBlock)

    Write-Host "[$testNum] $Name" -ForegroundColor Cyan
    try {
        $result = & $ScriptBlock
        if ($result) {
            Write-Host "  PASS" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host "  FAIL" -ForegroundColor Red
            $script:failed++
        }
    } catch {
        Write-Host "  FAIL - $_" -ForegroundColor Red
        $script:failed++
    }
    $script:testNum++
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "NETWORK CONNECTIVITY TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# Domain Controllers
Test-Item "Ping mcorp-dc (192.168.96.10)" { Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet }
Test-Item "Ping dcorp-dc (192.168.96.20)" { Test-Connection -ComputerName 192.168.96.20 -Count 2 -Quiet }
Test-Item "Ping ecorp-dc (192.168.96.100)" { Test-Connection -ComputerName 192.168.96.100 -Count 2 -Quiet }

# Member Servers
Test-Item "Ping dcorp-adminsrv (192.168.96.21)" { Test-Connection -ComputerName 192.168.96.21 -Count 2 -Quiet }
Test-Item "Ping dcorp-appsrv (192.168.96.22)" { Test-Connection -ComputerName 192.168.96.22 -Count 2 -Quiet }
Test-Item "Ping dcorp-ci (192.168.96.23)" { Test-Connection -ComputerName 192.168.96.23 -Count 2 -Quiet }
Test-Item "Ping dcorp-mgmt (192.168.96.24)" { Test-Connection -ComputerName 192.168.96.24 -Count 2 -Quiet }
Test-Item "Ping dcorp-mssql (192.168.96.25)" { Test-Connection -ComputerName 192.168.96.25 -Count 2 -Quiet }
Test-Item "Ping dcorp-sql1 (192.168.96.26)" { Test-Connection -ComputerName 192.168.96.26 -Count 2 -Quiet }

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "DNS RESOLUTION TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "Resolve mcorp-dc.moneycorp.local" {
    $ip = (Resolve-DnsName mcorp-dc.moneycorp.local -ErrorAction SilentlyContinue).IPAddress
    $ip -eq "192.168.96.10"
}

Test-Item "Resolve dcorp-dc.dollarcorp.moneycorp.local" {
    $ip = (Resolve-DnsName dcorp-dc.dollarcorp.moneycorp.local -ErrorAction SilentlyContinue).IPAddress
    $ip -eq "192.168.96.20"
}

Test-Item "Resolve ecorp-dc.eurocorp.local" {
    $ip = (Resolve-DnsName ecorp-dc.eurocorp.local -ErrorAction SilentlyContinue).IPAddress
    $ip -eq "192.168.96.100"
}

Test-Item "Resolve dcorp-adminsrv.dollarcorp.moneycorp.local" {
    $ip = (Resolve-DnsName dcorp-adminsrv.dollarcorp.moneycorp.local -ErrorAction SilentlyContinue).IPAddress
    $ip -eq "192.168.96.21"
}

Test-Item "Resolve dcorp-mssql.dollarcorp.moneycorp.local" {
    $ip = (Resolve-DnsName dcorp-mssql.dollarcorp.moneycorp.local -ErrorAction SilentlyContinue).IPAddress
    $ip -eq "192.168.96.25"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "DOMAIN TRUST TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "Parent-Child Trust: dollarcorp → moneycorp" {
    $trust = nltest /domain_trusts 2>$null | Select-String "moneycorp.local"
    $trust -match "moneycorp.local"
}

Test-Item "External Forest Trust: dollarcorp ↔ eurocorp" {
    $trust = nltest /domain_trusts 2>$null | Select-String "eurocorp.local"
    $trust -match "eurocorp.local"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "ACTIVE DIRECTORY QUERY TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "Query dollarcorp.moneycorp.local domain" {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'dollarcorp.moneycorp.local')))
    $domain.Name -eq "dollarcorp.moneycorp.local"
}

Test-Item "Query moneycorp.local domain" {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'moneycorp.local')))
    $domain.Name -eq "moneycorp.local"
}

Test-Item "Query eurocorp.local domain" {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', 'eurocorp.local')))
    $domain.Name -eq "eurocorp.local"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "LDAP CONNECTIVITY TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "LDAP to dcorp-dc (389)" { Test-NetConnection -ComputerName 192.168.96.20 -Port 389 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "LDAP to mcorp-dc (389)" { Test-NetConnection -ComputerName 192.168.96.10 -Port 389 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "LDAP to ecorp-dc (389)" { Test-NetConnection -ComputerName 192.168.96.100 -Port 389 | Select-Object -ExpandProperty TcpTestSucceeded }

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "SMB/RPC CONNECTIVITY TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "SMB to dcorp-dc (445)" { Test-NetConnection -ComputerName 192.168.96.20 -Port 445 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "SMB to dcorp-adminsrv (445)" { Test-NetConnection -ComputerName 192.168.96.21 -Port 445 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "SMB to dcorp-ci (445)" { Test-NetConnection -ComputerName 192.168.96.23 -Port 445 | Select-Object -ExpandProperty TcpTestSucceeded }

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "KERBEROS TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "Kerberos to dcorp-dc (88)" { Test-NetConnection -ComputerName 192.168.96.20 -Port 88 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "Kerberos to mcorp-dc (88)" { Test-NetConnection -ComputerName 192.168.96.10 -Port 88 | Select-Object -ExpandProperty TcpTestSucceeded }

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "SQL SERVER TESTS (for Lab 22-23)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "SQL to dcorp-mssql (1433)" { Test-NetConnection -ComputerName 192.168.96.25 -Port 1433 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "SQL to dcorp-sql1 (1433)" { Test-NetConnection -ComputerName 192.168.96.26 -Port 1433 | Select-Object -ExpandProperty TcpTestSucceeded }
Test-Item "SQL to dcorp-mgmt (1433)" { Test-NetConnection -ComputerName 192.168.96.24 -Port 1433 | Select-Object -ExpandProperty TcpTestSucceeded }

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "USER ENUMERATION TESTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Test-Item "Enumerate users in dollarcorp.moneycorp.local" {
    $users = Get-ADUser -Filter * -Server dcorp-dc -ErrorAction SilentlyContinue
    $users.Count -gt 0
}

Test-Item "Enumerate users in moneycorp.local" {
    $users = Get-ADUser -Filter * -Server mcorp-dc -ErrorAction SilentlyContinue
    $users.Count -gt 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "ALL TESTS PASSED - CRTP LAB IS READY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now proceed with all CRTP lab exercises:" -ForegroundColor Green
    Write-Host "  - Lab 14: Kerberoasting" -ForegroundColor White
    Write-Host "  - Lab 15: Unconstrained Delegation" -ForegroundColor White
    Write-Host "  - Lab 16: Constrained Delegation" -ForegroundColor White
    Write-Host "  - Lab 17: RBCD" -ForegroundColor White
    Write-Host "  - Lab 18-19: Parent-Child Trust Exploitation" -ForegroundColor White
    Write-Host "  - Lab 20: External Forest Trust" -ForegroundColor White
    Write-Host "  - Lab 22-23: SQL Server Database Links" -ForegroundColor White
} else {
    Write-Host "FAILURES DETECTED - Lab not fully ready" -ForegroundColor Red
    Write-Host "Fix the failed tests before proceeding with labs" -ForegroundColor Yellow
}

Write-Host ""
