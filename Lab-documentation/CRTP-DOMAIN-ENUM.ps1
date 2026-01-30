# ========================================
# CRTP - AUTOMATED AD DOMAIN ENUMERATION
# Based on CRTP Course Content (Lab 14)
# Run as: dollarcorp\student on dcorp-stdadmin
# ========================================

param(
    [string]$Domain = $null,
    [string]$OutputDir = "C:\AD\Enumeration",
    [switch]$SkipPowerView,
    [switch]$ExportCSV
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP AUTOMATED AD ENUMERATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "[+] Created output directory: $OutputDir" -ForegroundColor Green
}

# Timestamp for output files
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = "$OutputDir\CRTP-Enum-$timestamp.txt"

# Function to write output to both console and file
function Write-Output-Both {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $outputFile -Value $Message
}

# Start logging
Write-Output-Both "==============================================="
Write-Output-Both "CRTP AD ENUMERATION - $(Get-Date)"
Write-Output-Both "==============================================="
Write-Output-Both ""

# ========================================
# PHASE 1: LOAD POWERVIEW
# ========================================

if (-not $SkipPowerView) {
    Write-Host "[*] Loading PowerView..." -ForegroundColor Yellow

    $powerViewPaths = @(
        "C:\AD\Tools\PowerView.ps1",
        "C:\AD\Tools\PowerSploit\Recon\PowerView.ps1",
        "$PSScriptRoot\PowerView.ps1"
    )

    $powerViewLoaded = $false
    foreach ($path in $powerViewPaths) {
        if (Test-Path $path) {
            try {
                . $path
                Write-Host "[+] PowerView loaded from: $path" -ForegroundColor Green
                $powerViewLoaded = $true
                break
            } catch {
                Write-Host "[-] Failed to load from $path" -ForegroundColor Red
            }
        }
    }

    if (-not $powerViewLoaded) {
        Write-Host "[-] WARNING: PowerView not found! Some checks will be skipped." -ForegroundColor Red
        Write-Host "[*] Looking for PowerView in C:\AD\Tools\" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ========================================
# PHASE 2: CURRENT USER & DOMAIN INFO
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "CURRENT USER INFORMATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

$currentUser = whoami
$currentDomain = $env:USERDNSDOMAIN
Write-Output-Both "[+] Current User: $currentUser"
Write-Output-Both "[+] Current Domain: $currentDomain"
Write-Output-Both ""

# Current user groups
Write-Output-Both "[*] Current User Groups:"
$groups = whoami /groups /fo csv | ConvertFrom-Csv
foreach ($group in $groups) {
    Write-Output-Both "    $($group.'Group Name')"
}
Write-Output-Both ""

# Current user privileges
Write-Output-Both "[*] Current User Privileges:"
$privs = whoami /priv /fo csv | ConvertFrom-Csv
foreach ($priv in $privs) {
    if ($priv.'Privilege' -match "SeImpersonate|SeAssignPrimaryToken|SeDebug|SeTcb") {
        Write-Output-Both "    [!] $($priv.'Privilege') - $($priv.'State')" "Yellow"
    } else {
        Write-Output-Both "    $($priv.'Privilege') - $($priv.'State')"
    }
}
Write-Output-Both ""

# ========================================
# PHASE 3: DOMAIN ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "DOMAIN INFORMATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-Domain -ErrorAction SilentlyContinue) {
    $domainInfo = Get-Domain
    Write-Output-Both "[+] Domain Name: $($domainInfo.Name)"
    Write-Output-Both "[+] Domain SID: $($domainInfo.DomainSID)"
    Write-Output-Both "[+] Forest: $($domainInfo.Forest)"
    Write-Output-Both "[+] Domain Controllers: $($domainInfo.DomainControllers -join ', ')"
    Write-Output-Both ""

    # Get domain policy
    Write-Output-Both "[*] Domain Password Policy:"
    $policy = Get-DomainPolicyData
    if ($policy.SystemAccess) {
        Write-Output-Both "    Min Password Length: $($policy.SystemAccess.MinimumPasswordLength)"
        Write-Output-Both "    Password History: $($policy.SystemAccess.PasswordHistorySize)"
        Write-Output-Both "    Max Password Age: $($policy.SystemAccess.MaximumPasswordAge) days"
        Write-Output-Both "    Lockout Threshold: $($policy.SystemAccess.LockoutBadCount)"
        Write-Output-Both "    Lockout Duration: $($policy.SystemAccess.LockoutDuration) minutes"
    }
    Write-Output-Both ""
} else {
    Write-Output-Both "[-] PowerView not loaded, using native .NET methods" "Yellow"
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    Write-Output-Both "[+] Domain Name: $($domain.Name)"
    Write-Output-Both "[+] Forest: $($domain.Forest)"
    Write-Output-Both "[+] Domain Controllers: $($domain.DomainControllers.Name -join ', ')"
    Write-Output-Both ""
}

# ========================================
# PHASE 4: DOMAIN CONTROLLERS
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "DOMAIN CONTROLLERS" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainController -ErrorAction SilentlyContinue) {
    $dcs = Get-DomainController
    foreach ($dc in $dcs) {
        Write-Output-Both "[+] DC: $($dc.Name)"
        Write-Output-Both "    IP: $($dc.IPAddress)"
        Write-Output-Both "    OS: $($dc.OSVersion)"
        Write-Output-Both "    Site: $($dc.SiteName)"
        Write-Output-Both ""
    }
} else {
    $dcs = nltest /dclist:$currentDomain 2>&1 | Select-String "\\\\"
    foreach ($dc in $dcs) {
        Write-Output-Both "[+] DC: $dc"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 5: DOMAIN TRUSTS
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "DOMAIN TRUSTS" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainTrust -ErrorAction SilentlyContinue) {
    $trusts = Get-DomainTrust
    foreach ($trust in $trusts) {
        Write-Output-Both "[+] Trust: $($trust.SourceName) -> $($trust.TargetName)"
        Write-Output-Both "    Direction: $($trust.TrustDirection)"
        Write-Output-Both "    Type: $($trust.TrustType)"
        Write-Output-Both "    Attributes: $($trust.TrustAttributes)"
        Write-Output-Both ""
    }
} else {
    $trusts = nltest /domain_trusts 2>&1
    Write-Output-Both $trusts
    Write-Output-Both ""
}

# Forest trusts
if (Get-Command Get-ForestDomain -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Forest Domains:"
    $forestDomains = Get-ForestDomain
    foreach ($fd in $forestDomains) {
        Write-Output-Both "    [+] $($fd.Name)"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 6: USER ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "USER ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainUser -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Enumerating all domain users..."
    $users = Get-DomainUser
    Write-Output-Both "[+] Total Users: $($users.Count)"
    Write-Output-Both ""

    # Export to CSV if requested
    if ($ExportCSV) {
        $users | Select-Object samaccountname, name, description, memberof | Export-Csv "$OutputDir\Users-$timestamp.csv" -NoTypeInformation
        Write-Output-Both "[+] Exported users to: $OutputDir\Users-$timestamp.csv" "Green"
    }

    # Find interesting users
    Write-Output-Both "[*] Users with 'admin' in name:"
    $adminUsers = Get-DomainUser | Where-Object { $_.samaccountname -match 'admin' }
    foreach ($user in $adminUsers) {
        Write-Output-Both "    [+] $($user.samaccountname) - $($user.description)"
    }
    Write-Output-Both ""

    # Service accounts
    Write-Output-Both "[*] Users with 'svc' or 'service' in name:"
    $svcUsers = Get-DomainUser | Where-Object { $_.samaccountname -match 'svc|service' }
    foreach ($user in $svcUsers) {
        Write-Output-Both "    [+] $($user.samaccountname) - $($user.description)"
    }
    Write-Output-Both ""

    # Users with SPNs (Kerberoastable)
    Write-Output-Both "[*] Users with SPNs (Kerberoastable):" "Yellow"
    $spnUsers = Get-DomainUser -SPN
    foreach ($user in $spnUsers) {
        Write-Output-Both "    [!] $($user.samaccountname)" "Yellow"
        Write-Output-Both "        SPN: $($user.serviceprincipalname)" "Yellow"
    }
    if ($spnUsers.Count -eq 0) {
        Write-Output-Both "    [-] No users with SPNs found"
    }
    Write-Output-Both ""

    # AS-REP Roastable users
    Write-Output-Both "[*] AS-REP Roastable Users (No Preauth Required):" "Yellow"
    $asrepUsers = Get-DomainUser -PreauthNotRequired
    foreach ($user in $asrepUsers) {
        Write-Output-Both "    [!] $($user.samaccountname)" "Yellow"
    }
    if ($asrepUsers.Count -eq 0) {
        Write-Output-Both "    [-] No AS-REP roastable users found"
    }
    Write-Output-Both ""

    # Users with passwords not required
    Write-Output-Both "[*] Users with password not required:"
    $noPassUsers = Get-DomainUser -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=32)"
    foreach ($user in $noPassUsers) {
        Write-Output-Both "    [!] $($user.samaccountname)" "Yellow"
    }
    if ($noPassUsers.Count -eq 0) {
        Write-Output-Both "    [-] No users with password not required"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 7: GROUP ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "GROUP ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainGroup -ErrorAction SilentlyContinue) {
    # Domain Admins
    Write-Output-Both "[*] Domain Admins:"
    $domainAdmins = Get-DomainGroupMember -Identity "Domain Admins" -Recurse
    foreach ($admin in $domainAdmins) {
        Write-Output-Both "    [+] $($admin.MemberName)"
    }
    Write-Output-Both ""

    # Enterprise Admins
    Write-Output-Both "[*] Enterprise Admins:"
    $entAdmins = Get-DomainGroupMember -Identity "Enterprise Admins" -Recurse -ErrorAction SilentlyContinue
    foreach ($admin in $entAdmins) {
        Write-Output-Both "    [+] $($admin.MemberName)"
    }
    Write-Output-Both ""

    # Schema Admins
    Write-Output-Both "[*] Schema Admins:"
    $schemaAdmins = Get-DomainGroupMember -Identity "Schema Admins" -Recurse -ErrorAction SilentlyContinue
    foreach ($admin in $schemaAdmins) {
        Write-Output-Both "    [+] $($admin.MemberName)"
    }
    Write-Output-Both ""

    # Administrators
    Write-Output-Both "[*] Local Administrators Group:"
    $localAdmins = Get-DomainGroupMember -Identity "Administrators" -Recurse
    foreach ($admin in $localAdmins) {
        Write-Output-Both "    [+] $($admin.MemberName)"
    }
    Write-Output-Both ""

    # All groups with 'admin' in name
    Write-Output-Both "[*] All groups with 'admin' in name:"
    $adminGroups = Get-DomainGroup | Where-Object { $_.samaccountname -match 'admin' }
    foreach ($group in $adminGroups) {
        Write-Output-Both "    [+] $($group.samaccountname) - $($group.description)"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 8: COMPUTER ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "COMPUTER ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainComputer -ErrorAction SilentlyContinue) {
    $computers = Get-DomainComputer
    Write-Output-Both "[+] Total Computers: $($computers.Count)"
    Write-Output-Both ""

    # List all computers
    Write-Output-Both "[*] All Domain Computers:"
    foreach ($comp in $computers) {
        Write-Output-Both "    [+] $($comp.dnshostname)"
        Write-Output-Both "        OS: $($comp.operatingsystem)"
        Write-Output-Both "        IP: $($comp.ipaddress)"
    }
    Write-Output-Both ""

    # Export to CSV if requested
    if ($ExportCSV) {
        $computers | Select-Object dnshostname, operatingsystem, ipaddress | Export-Csv "$OutputDir\Computers-$timestamp.csv" -NoTypeInformation
        Write-Output-Both "[+] Exported computers to: $OutputDir\Computers-$timestamp.csv" "Green"
    }

    # Servers
    Write-Output-Both "[*] Servers:"
    $servers = Get-DomainComputer -OperatingSystem "*Server*"
    foreach ($srv in $servers) {
        Write-Output-Both "    [+] $($srv.dnshostname) - $($srv.operatingsystem)"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 9: DELEGATION ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "DELEGATION ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainComputer -ErrorAction SilentlyContinue) {
    # Unconstrained Delegation
    Write-Output-Both "[*] Computers with Unconstrained Delegation:" "Yellow"
    $unconstrainedComps = Get-DomainComputer -Unconstrained | Where-Object { $_.samaccountname -notmatch 'DC' }
    foreach ($comp in $unconstrainedComps) {
        Write-Output-Both "    [!] $($comp.dnshostname)" "Yellow"
    }
    if ($unconstrainedComps.Count -eq 0) {
        Write-Output-Both "    [-] No computers with unconstrained delegation (excluding DCs)"
    }
    Write-Output-Both ""

    # Constrained Delegation
    Write-Output-Both "[*] Computers/Users with Constrained Delegation:" "Yellow"
    $constrainedComps = Get-DomainComputer -TrustedToAuth
    foreach ($comp in $constrainedComps) {
        Write-Output-Both "    [!] $($comp.dnshostname)" "Yellow"
        Write-Output-Both "        Allowed to: $($comp.msds-allowedtodelegateto)" "Yellow"
    }

    $constrainedUsers = Get-DomainUser -TrustedToAuth
    foreach ($user in $constrainedUsers) {
        Write-Output-Both "    [!] $($user.samaccountname)" "Yellow"
        Write-Output-Both "        Allowed to: $($user.'msds-allowedtodelegateto')" "Yellow"
    }

    if ($constrainedComps.Count -eq 0 -and $constrainedUsers.Count -eq 0) {
        Write-Output-Both "    [-] No constrained delegation found"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 10: SQL SERVER ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "SQL SERVER ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainComputer -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Computers with SQL Server:"
    $sqlServers = Get-DomainComputer | Where-Object { $_.serviceprincipalname -match 'MSSQLSvc' }
    foreach ($sql in $sqlServers) {
        Write-Output-Both "    [+] $($sql.dnshostname)"
        $spns = $sql.serviceprincipalname | Where-Object { $_ -match 'MSSQLSvc' }
        foreach ($spn in $spns) {
            Write-Output-Both "        SPN: $spn"
        }
    }

    if ($sqlServers.Count -eq 0) {
        Write-Output-Both "    [-] No SQL servers found via SPN"
    }
    Write-Output-Both ""
}

# Alternative: Find by hostname pattern
Write-Output-Both "[*] Computers with 'SQL' or 'DB' in hostname:"
$sqlByName = Get-DomainComputer | Where-Object { $_.dnshostname -match 'sql|db|mssql' }
foreach ($sql in $sqlByName) {
    Write-Output-Both "    [+] $($sql.dnshostname)"
}
Write-Output-Both ""

# ========================================
# PHASE 11: ACL ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "ACL ENUMERATION (Interesting ACLs)" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Find-InterestingDomainAcl -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Finding interesting ACLs (this may take a while)..."
    $interestingAcls = Find-InterestingDomainAcl -ResolveGUIDs

    if ($interestingAcls) {
        Write-Output-Both "[+] Found $($interestingAcls.Count) interesting ACLs"
        foreach ($acl in $interestingAcls | Select-Object -First 20) {
            Write-Output-Both "    [+] $($acl.IdentityReferenceName) has $($acl.ActiveDirectoryRights) on $($acl.ObjectDN)" "Yellow"
        }

        if ($interestingAcls.Count -gt 20) {
            Write-Output-Both "    [*] ... and $($interestingAcls.Count - 20) more (see CSV export)" "Yellow"
        }

        if ($ExportCSV) {
            $interestingAcls | Export-Csv "$OutputDir\ACLs-$timestamp.csv" -NoTypeInformation
            Write-Output-Both "[+] Exported ACLs to: $OutputDir\ACLs-$timestamp.csv" "Green"
        }
    } else {
        Write-Output-Both "    [-] No interesting ACLs found"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 12: GPO ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "GROUP POLICY OBJECT (GPO) ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Get-DomainGPO -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Domain GPOs:"
    $gpos = Get-DomainGPO
    foreach ($gpo in $gpos) {
        Write-Output-Both "    [+] $($gpo.displayname)"
        Write-Output-Both "        Path: $($gpo.gpcfilesyspath)"
    }
    Write-Output-Both ""

    if ($ExportCSV) {
        $gpos | Select-Object displayname, gpcfilesyspath | Export-Csv "$OutputDir\GPOs-$timestamp.csv" -NoTypeInformation
        Write-Output-Both "[+] Exported GPOs to: $OutputDir\GPOs-$timestamp.csv" "Green"
    }
}

# ========================================
# PHASE 13: SHARE ENUMERATION
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "NETWORK SHARE ENUMERATION" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Invoke-ShareFinder -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Finding network shares (this may take a while)..."
    $shares = Invoke-ShareFinder -CheckShareAccess

    if ($shares) {
        Write-Output-Both "[+] Found $($shares.Count) accessible shares"
        foreach ($share in $shares | Select-Object -First 50) {
            Write-Output-Both "    [+] \\$($share.ComputerName)\$($share.Name)"
            if ($share.Remark) {
                Write-Output-Both "        Remark: $($share.Remark)"
            }
        }

        if ($shares.Count -gt 50) {
            Write-Output-Both "    [*] ... and $($shares.Count - 50) more (see CSV export)"
        }

        if ($ExportCSV) {
            $shares | Export-Csv "$OutputDir\Shares-$timestamp.csv" -NoTypeInformation
            Write-Output-Both "[+] Exported shares to: $OutputDir\Shares-$timestamp.csv" "Green"
        }
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 14: LOCAL ADMIN MAPPING
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "LOCAL ADMIN MAPPING" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Find-LocalAdminAccess -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Finding machines where current user has local admin access..."
    $localAdminAccess = Find-LocalAdminAccess

    if ($localAdminAccess) {
        Write-Output-Both "[+] Current user has local admin on:" "Green"
        foreach ($computer in $localAdminAccess) {
            Write-Output-Both "    [!] $computer" "Green"
        }
    } else {
        Write-Output-Both "    [-] No local admin access found"
    }
    Write-Output-Both ""
}

# ========================================
# PHASE 15: DOMAIN ADMIN SESSION HUNTING
# ========================================

Write-Output-Both "========================================" "Cyan"
Write-Output-Both "DOMAIN ADMIN SESSION HUNTING" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""

if (Get-Command Invoke-UserHunter -ErrorAction SilentlyContinue) {
    Write-Output-Both "[*] Hunting for Domain Admin sessions (this may take a while)..."
    $daSessions = Invoke-UserHunter -GroupName "Domain Admins" -CheckAccess

    if ($daSessions) {
        Write-Output-Both "[+] Found Domain Admin sessions:" "Yellow"
        foreach ($session in $daSessions) {
            Write-Output-Both "    [!] $($session.UserName) logged into $($session.ComputerName)" "Yellow"
        }

        if ($ExportCSV) {
            $daSessions | Export-Csv "$OutputDir\DA-Sessions-$timestamp.csv" -NoTypeInformation
            Write-Output-Both "[+] Exported DA sessions to: $OutputDir\DA-Sessions-$timestamp.csv" "Green"
        }
    } else {
        Write-Output-Both "    [-] No Domain Admin sessions found"
    }
    Write-Output-Both ""
}

# ========================================
# SUMMARY
# ========================================

Write-Output-Both ""
Write-Output-Both "========================================" "Cyan"
Write-Output-Both "ENUMERATION COMPLETE" "Cyan"
Write-Output-Both "========================================" "Cyan"
Write-Output-Both ""
Write-Output-Both "[+] Enumeration completed: $(Get-Date)" "Green"
Write-Output-Both "[+] Results saved to: $outputFile" "Green"

if ($ExportCSV) {
    Write-Output-Both "[+] CSV exports saved to: $OutputDir" "Green"
}

Write-Output-Both ""
Write-Output-Both "NEXT STEPS:" "Yellow"
Write-Output-Both "  1. Review Kerberoastable accounts and attempt to crack hashes" "White"
Write-Output-Both "  2. Check AS-REP roastable accounts" "White"
Write-Output-Both "  3. Investigate unconstrained/constrained delegation" "White"
Write-Output-Both "  4. Enumerate SQL servers and linked servers" "White"
Write-Output-Both "  5. Hunt for Domain Admin sessions" "White"
Write-Output-Both "  6. Check for local privilege escalation on current machine" "White"
Write-Output-Both ""
