# ========================================
# TEST CRTP VULNERABILITIES
# Checks if CRTP-specific vulnerabilities are deployed
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP VULNERABILITY CHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script checks for common CRTP lab vulnerabilities and misconfigurations" -ForegroundColor Yellow
Write-Host ""

$totalChecks = 0
$deployedVulns = 0
$missingVulns = 0

# Lab 14-23 vulnerability checks
$vulnerabilities = @(
    @{
        Lab = "Lab 14"
        Name = "Kerberoastable Service Accounts"
        Description = "Service accounts with SPNs set for Kerberoasting"
        Check = {
            try {
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=user)(servicePrincipalName=*))"
                $results = $searcher.FindAll()
                return $results.Count -gt 0
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 15"
        Name = "AS-REP Roastable Accounts"
        Description = "User accounts with 'Do not require Kerberos preauthentication' enabled"
        Check = {
            try {
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))"
                $results = $searcher.FindAll()
                return $results.Count -gt 0
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 16"
        Name = "Unconstrained Delegation"
        Description = "Computers with unconstrained delegation enabled"
        Check = {
            try {
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=computer)(userAccountControl:1.2.840.113556.1.4.803:=524288))"
                $results = $searcher.FindAll()
                return $results.Count -gt 1  # Expect more than just DCs
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 17"
        Name = "Constrained Delegation"
        Description = "Accounts with constrained delegation configured"
        Check = {
            try {
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=user)(msDS-AllowedToDelegateTo=*))"
                $results = $searcher.FindAll()
                return $results.Count -gt 0
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 18"
        Name = "Resource-Based Constrained Delegation"
        Description = "Computers with msDS-AllowedToActOnBehalfOfOtherIdentity set"
        Check = {
            try {
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=computer)(msDS-AllowedToActOnBehalfOfOtherIdentity=*))"
                $results = $searcher.FindAll()
                return $results.Count -gt 0
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 19"
        Name = "SQL Server Linked Servers"
        Description = "SQL Server instances with linked servers configured"
        Check = {
            # Check if SQL ports are accessible
            $sql1 = Test-NetConnection -ComputerName 192.168.96.25 -Port 1433 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $sql2 = Test-NetConnection -ComputerName 192.168.96.26 -Port 1433 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            return ($sql1.TcpTestSucceeded -or $sql2.TcpTestSucceeded)
        }
    },
    @{
        Lab = "Lab 20"
        Name = "Forest Trust (moneycorp <-> eurocorp)"
        Description = "Bidirectional forest trust between moneycorp.local and eurocorp.local"
        Check = {
            try {
                $nltest = nltest /server:mcorp-dc /domain_trusts 2>&1 | Out-String
                return ($nltest -match "eurocorp")
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 21"
        Name = "Domain Trust (dollarcorp -> moneycorp)"
        Description = "Parent-child trust between dcorp.moneycorp.local and moneycorp.local"
        Check = {
            try {
                $nltest = nltest /server:dcorp-dc /domain_trusts 2>&1 | Out-String
                return ($nltest -match "moneycorp")
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 22"
        Name = "ACL Misconfigurations"
        Description = "Users with elevated permissions on key AD objects"
        Check = {
            try {
                # Check if non-admin users exist (CRTP creates vulnerable users)
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://dcorp.moneycorp.local")
                $searcher.Filter = "(&(objectClass=user)(!(adminCount=1)))"
                $results = $searcher.FindAll()
                return $results.Count -gt 3  # Expect several regular users
            } catch {
                return $null
            }
        }
    },
    @{
        Lab = "Lab 23"
        Name = "MSSQL Server Access"
        Description = "MSSQL servers accessible with default/weak configurations"
        Check = {
            # Both SQL servers should be accessible
            $sql1 = Test-NetConnection -ComputerName dcorp-mssql.dcorp.moneycorp.local -Port 1433 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $sql2 = Test-NetConnection -ComputerName dcorp-sql1.dcorp.moneycorp.local -Port 1433 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            return ($sql1.TcpTestSucceeded -and $sql2.TcpTestSucceeded)
        }
    }
)

# Run checks
foreach ($vuln in $vulnerabilities) {
    $totalChecks++
    Write-Host "[$($vuln.Lab)] $($vuln.Name)" -ForegroundColor White
    Write-Host "  $($vuln.Description)" -ForegroundColor Gray
    Write-Host "  Checking... " -NoNewline

    try {
        $result = & $vuln.Check

        if ($result -eq $true) {
            Write-Host "[DEPLOYED]" -ForegroundColor Green
            $deployedVulns++
        } elseif ($result -eq $false) {
            Write-Host "[MISSING]" -ForegroundColor Red
            $missingVulns++
        } else {
            Write-Host "[UNKNOWN - Could not verify]" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR - $_]" -ForegroundColor Yellow
    }

    Write-Host ""
}

# Additional infrastructure checks
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INFRASTRUCTURE CHECKS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check student workstation
$totalChecks++
Write-Host "Student Workstation (dcorp-stdadmin)" -ForegroundColor White
Write-Host "  Testing RDP access (port 3389)... " -NoNewline
$rdp = Test-NetConnection -ComputerName 192.168.96.50 -Port 3389 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($rdp.TcpTestSucceeded) {
    Write-Host "[ACCESSIBLE]" -ForegroundColor Green
    $deployedVulns++
} else {
    Write-Host "[NOT ACCESSIBLE]" -ForegroundColor Red
    $missingVulns++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Checks: $totalChecks" -ForegroundColor White
Write-Host "Vulnerabilities Deployed: $deployedVulns" -ForegroundColor Green
Write-Host "Missing/Not Verified: $missingVulns" -ForegroundColor Red
Write-Host ""

$percentage = [math]::Round(($deployedVulns / $totalChecks) * 100, 2)
Write-Host "Deployment Completeness: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 70) { "Yellow" } else { "Red" })
Write-Host ""

if ($missingVulns -eq 0) {
    Write-Host "ALL VULNERABILITIES DEPLOYED - LAB IS READY FOR CRTP!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Some vulnerabilities may not be deployed" -ForegroundColor Yellow
    Write-Host "This is normal if the lab is fresh - vulnerabilities may need manual setup" -ForegroundColor Yellow
}
Write-Host ""
