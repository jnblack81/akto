# CRTP Lab Deployment Guide

## Overview

This guide configures the **Certified Red Team Professional (CRTP)** lab environment with proper forest trust between domains.

## Lab Structure

```
moneycorp.local (Forest Root)
  └── dollarcorp.moneycorp.local (Child Domain)

eurocorp.local (Separate Forest)

Forest Trust: moneycorp.local <---> eurocorp.local (Bidirectional)
```

## Domain Controllers

| Hostname | Domain | IP Address | Role |
|----------|--------|------------|------|
| mcorp-dc | moneycorp.local | 192.168.96.10 | Forest Root DC |
| dcorp-dc | dollarcorp.moneycorp.local | 192.168.96.12 | Child Domain DC |
| ecorp-dc | eurocorp.local | 192.168.96.11 | Separate Forest DC |

## Credentials

**All domains:**
- Username: `Administrator`
- Password: `Psychi@Lab2024!`

## Deployment Steps

### Step 1: Configure mcorp-dc (moneycorp.local)

1. Log into **mcorp-dc** as `moneycorp\Administrator`
2. Copy `CRTP-Lab-Setup-MCORP.ps1` to the server
3. Run PowerShell as Administrator
4. Execute:

```powershell
cd C:\path\to\scripts
.\CRTP-Lab-Setup-MCORP.ps1
```

**What this does:**
- Creates DNS conditional forwarder for eurocorp.local
- Tests DNS resolution and network connectivity
- Removes any broken existing trusts
- Creates bidirectional forest trust to eurocorp.local
- Verifies the trust configuration

**Expected Output:**
```
[OK] DNS forwarder created
[OK] Network connectivity to ecorp-dc (192.168.96.11)
[OK] Forest trust created successfully!
[OK] Trust object exists
```

---

### Step 2: Configure ecorp-dc (eurocorp.local)

1. Log into **ecorp-dc** as `eurocorp\Administrator`
2. Copy `CRTP-Lab-Setup-ECORP.ps1` to the server
3. Run PowerShell as Administrator
4. Execute:

```powershell
cd C:\path\to\scripts
.\CRTP-Lab-Setup-ECORP.ps1
```

**What this does:**
- Creates DNS conditional forwarder for moneycorp.local
- Tests DNS resolution and network connectivity
- Removes any broken existing trusts
- Completes bidirectional forest trust to moneycorp.local
- Verifies the trust configuration

**Expected Output:**
```
[OK] DNS forwarder created
[OK] Network connectivity to mcorp-dc (192.168.96.10)
[OK] Forest trust created successfully!
[OK] Trust verification successful!
```

---

### Step 3: Verify Configuration

Run the verification script from **ANY** domain controller:

```powershell
.\CRTP-Lab-Verify.ps1
```

**What this checks:**
- All trust relationships
- DNS resolution for all DCs
- Network connectivity between DCs
- Cross-forest AD queries

**Expected Output:**
```
Trust: eurocorp.local
  Direction: Bidirectional
  Type: Forest
  Forest Transitive: True

[OK] Successfully queried eurocorp.local
[OK] Successfully queried moneycorp.local
```

---

## Verification Commands

### From mcorp-dc (moneycorp.local)

```powershell
# Check trusts
Get-ADTrust -Filter * | Format-Table Name, Direction, TrustType

# Query eurocorp domain
Get-ADDomain -Server eurocorp.local

# List users in eurocorp
Get-ADUser -Filter * -Server eurocorp.local | Select-Object Name, SamAccountName
```

### From dcorp-dc (dollarcorp.moneycorp.local)

```powershell
# Should see eurocorp through transitive trust
nltest /domain_trusts /all_trusts

# Query eurocorp domain (through parent trust)
Get-ADDomain -Server eurocorp.local

# Test cross-forest access
runas /user:eurocorp\Administrator powershell
```

### From ecorp-dc (eurocorp.local)

```powershell
# Check trusts
Get-ADTrust -Filter * | Format-Table Name, Direction, TrustType

# Query moneycorp domain
Get-ADDomain -Server moneycorp.local

# Query child domain
Get-ADDomain -Server dollarcorp.moneycorp.local
```

---

## Troubleshooting

### Trust Creation Fails with "Access is denied"

**Problem:** Trust object already exists but is broken

**Solution:**
```powershell
# On mcorp-dc
Remove-ADTrust -Identity "eurocorp.local" -Confirm:$false

# On ecorp-dc
Remove-ADTrust -Identity "moneycorp.local" -Confirm:$false

# Wait 30 seconds, then re-run setup scripts
```

### DNS Resolution Fails

**Problem:** Cannot resolve DCs across forests

**Solution:**
```powershell
# On mcorp-dc
Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11

# On ecorp-dc
Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10
```

### Network Connectivity Issues

**Problem:** Cannot ping DCs

**Solution:**
1. Check VirtualBox network settings (should be Internal Network or Host-Only)
2. Verify IP addresses match the expected configuration
3. Check Windows Firewall on all DCs:

```powershell
# Allow all ICMP (ping)
New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow

# Or disable firewall (lab only!)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

### Trust Verification Fails

**Problem:** `netdom trust /verify` fails

**Solution:**
```powershell
# Reset trust password on both sides

# On mcorp-dc
netdom trust moneycorp.local /domain:eurocorp.local /resetpassword /passwordt:Psychi@Lab2024! /usero:eurocorp\Administrator /passwordo:Psychi@Lab2024!

# On ecorp-dc
netdom trust eurocorp.local /domain:moneycorp.local /resetpassword /passwordt:Psychi@Lab2024! /usero:moneycorp\Administrator /passwordo:Psychi@Lab2024!

# Verify
netdom trust moneycorp.local /domain:eurocorp.local /verify /usero:eurocorp\Administrator /passwordo:Psychi@Lab2024!
```

---

## Testing CRTP Scenarios

### Test 1: Cross-Forest User Enumeration

From dcorp-dc:

```powershell
# Enumerate eurocorp users
Get-ADUser -Filter * -Server eurocorp.local

# Enumerate groups
Get-ADGroup -Filter * -Server eurocorp.local
```

### Test 2: Cross-Forest Authentication

From dcorp-dc:

```powershell
# Authenticate as eurocorp user
runas /user:eurocorp\Administrator cmd

# Or with PowerShell credential
$cred = Get-Credential eurocorp\Administrator
Enter-PSSession -ComputerName ecorp-dc.eurocorp.local -Credential $cred
```

### Test 3: Kerberos Trust Tickets

From dcorp-dc:

```powershell
# Request TGT for eurocorp
klist purge
klist get krbtgt/eurocorp.local

# List tickets
klist
```

---

## What Makes This CRTP-Like

The CRTP lab includes these trust relationships for practicing:

1. **Parent-Child Trust** (Automatic)
   - moneycorp.local ↔ dollarcorp.moneycorp.local
   - Transitive, bidirectional
   - Used for intra-forest attacks

2. **Forest Trust** (Manual - configured by these scripts)
   - moneycorp.local ↔ eurocorp.local
   - Transitive, bidirectional
   - Used for cross-forest attacks

3. **Transitive Access**
   - dollarcorp can access eurocorp through parent (moneycorp)
   - Enables multi-hop attack paths
   - Simulates real enterprise environments

---

## Common CRTP Attack Paths

Once trusts are configured, practice these attacks:

### From dollarcorp.moneycorp.local

1. **Enumerate Trust**
   ```powershell
   Get-ADTrust -Filter *
   nltest /domain_trusts
   ```

2. **Enumerate eurocorp Users**
   ```powershell
   Get-ADUser -Filter * -Server eurocorp.local
   ```

3. **Map Trust Relationships**
   ```powershell
   Import-Module PowerView
   Get-DomainTrust
   Get-DomainTrust -Domain eurocorp.local
   ```

4. **Cross-Forest Kerberoasting**
   ```powershell
   Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Server eurocorp.local
   ```

5. **Trust Account Compromise**
   - Extract trust keys
   - Forge inter-realm TGTs (SID history injection)

---

## Files Included

| File | Purpose | Run On |
|------|---------|--------|
| `CRTP-Lab-Setup-MCORP.ps1` | Configure moneycorp forest root | mcorp-dc |
| `CRTP-Lab-Setup-ECORP.ps1` | Configure eurocorp forest | ecorp-dc |
| `CRTP-Lab-Verify.ps1` | Verify trust configuration | Any DC |
| `CRTP-LAB-DEPLOYMENT.md` | This deployment guide | Documentation |

---

## Quick Deployment Checklist

- [ ] VMs are running (mcorp-dc, dcorp-dc, ecorp-dc)
- [ ] Network connectivity verified (all DCs can ping each other)
- [ ] DNS is working (forward/reverse lookups)
- [ ] Run `CRTP-Lab-Setup-MCORP.ps1` on mcorp-dc
- [ ] Run `CRTP-Lab-Setup-ECORP.ps1` on ecorp-dc
- [ ] Run `CRTP-Lab-Verify.ps1` to confirm
- [ ] Test cross-forest queries work
- [ ] Begin CRTP training exercises

---

## Support

If trust configuration fails:

1. Check the script output for specific errors
2. Verify network and DNS configuration
3. Use the troubleshooting section above
4. Check Windows Event Logs (Directory Service logs)
5. Ensure all DCs have correct time sync

---

## License

These scripts are provided for authorized security training and research purposes only.

**Use only in isolated lab environments.**

---

**Happy Hunting! 🎯**
