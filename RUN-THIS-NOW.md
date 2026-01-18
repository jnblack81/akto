# RUN THIS NOW - EXACT INSTRUCTIONS

## YOU ARE ON: dcorp-dc (dollarcorp.moneycorp.local)

## STEP 1: Get the script files

The scripts are in this repository at:
```
/home/user/akto/DEPLOY-CRTP-LAB-NOW.ps1
```

**OPTION A: If you have VirtualBox shared folder (Z: drive or similar)**

From dcorp-dc PowerShell:
```powershell
# Copy the master script from shared folder
Copy-Item "\\Vboxsvr\<YOUR_SHARE>\akto\DEPLOY-CRTP-LAB-NOW.ps1" -Destination "C:\Scripts\DEPLOY-CRTP-LAB-NOW.ps1"
```

**OPTION B: Manual copy**
1. Open the file `/home/user/akto/DEPLOY-CRTP-LAB-NOW.ps1` on your host
2. Copy ALL the content
3. On dcorp-dc, open PowerShell ISE
4. Paste the content
5. Save as `C:\Scripts\DEPLOY-CRTP-LAB-NOW.ps1`

---

## STEP 2: Run on FIRST domain controller

**On dcorp-dc (where you are now):**

```powershell
# Create scripts folder
New-Item -ItemType Directory -Path "C:\Scripts" -Force

# Go to scripts folder
cd C:\Scripts

# If you copied the file, run it:
.\DEPLOY-CRTP-LAB-NOW.ps1
```

**This will configure the moneycorp side of the trust.**

---

## STEP 3: Copy script to ecorp-dc

**From dcorp-dc, copy to ecorp-dc:**

**METHOD 1 - Using shared folder:**
Just access ecorp-dc and copy from the same shared folder location

**METHOD 2 - Using PowerShell remoting:**
```powershell
# This might not work if WinRM isn't configured
$cred = Get-Credential eurocorp\Administrator
Copy-Item "C:\Scripts\DEPLOY-CRTP-LAB-NOW.ps1" -Destination "\\ecorp-dc\C$\Scripts\" -Credential $cred
```

**METHOD 3 - Manual (EASIEST):**
1. Log into ecorp-dc console in VirtualBox
2. Open PowerShell ISE
3. Copy the ENTIRE content of DEPLOY-CRTP-LAB-NOW.ps1
4. Paste into ISE
5. Save as `C:\Scripts\DEPLOY-CRTP-LAB-NOW.ps1`

---

## STEP 4: Run on ecorp-dc

**Log into ecorp-dc as eurocorp\Administrator**

```powershell
# Create scripts folder
New-Item -ItemType Directory -Path "C:\Scripts" -Force

# Go to scripts folder
cd C:\Scripts

# Run the deployment script
.\DEPLOY-CRTP-LAB-NOW.ps1
```

**This completes the other side of the trust.**

---

## STEP 5: Verify it worked

**From ANY domain controller, run:**

```powershell
# Check trusts
Get-ADTrust -Filter * | Format-Table Name, Direction, TrustType

# Test cross-forest query from moneycorp
Get-ADDomain -Server eurocorp.local

# Test cross-forest query from eurocorp
Get-ADDomain -Server moneycorp.local

# Show all trusts
nltest /domain_trusts /all_trusts
```

**If you see:**
- Trust to eurocorp.local (from moneycorp side)
- Trust to moneycorp.local (from eurocorp side)
- Both are "Bidirectional" and "Forest" type

**YOU'RE DONE!**

---

## IF IT DOESN'T WORK

**Check DNS first:**

```powershell
# From mcorp-dc or dcorp-dc:
nslookup ecorp-dc.eurocorp.local

# From ecorp-dc:
nslookup mcorp-dc.moneycorp.local
```

**Check network:**

```powershell
# From mcorp-dc or dcorp-dc:
Test-Connection 192.168.96.11

# From ecorp-dc:
Test-Connection 192.168.96.10
```

**If DNS or network fails, fix that FIRST before trust will work.**

---

## EXACT COPY-PASTE COMMANDS

### ON DCORP-DC RIGHT NOW:

```powershell
New-Item -ItemType Directory -Path "C:\Scripts" -Force
cd C:\Scripts
# Now copy DEPLOY-CRTP-LAB-NOW.ps1 to C:\Scripts\
# Then run:
.\DEPLOY-CRTP-LAB-NOW.ps1
```

### THEN ON ECORP-DC:

```powershell
New-Item -ItemType Directory -Path "C:\Scripts" -Force
cd C:\Scripts
# Copy DEPLOY-CRTP-LAB-NOW.ps1 to C:\Scripts\
# Then run:
.\DEPLOY-CRTP-LAB-NOW.ps1
```

### DONE.

---

## SIMPLEST WAY - MANUAL CONFIGURATION

If the script doesn't work, here's the MANUAL way:

### ON MCORP-DC:

```powershell
# 1. DNS forwarder
Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11

# 2. Remove broken trust if exists
Remove-ADTrust -Identity "eurocorp.local" -Confirm:$false

# 3. Create trust
$pass = ConvertTo-SecureString "Psychi@Lab2024!" -AsPlainText -Force
Add-ADTrust -Name "eurocorp.local" -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $pass -Confirm:$false
```

### ON ECORP-DC:

```powershell
# 1. DNS forwarder
Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10

# 2. Remove broken trust if exists
Remove-ADTrust -Identity "moneycorp.local" -Confirm:$false

# 3. Create trust
$pass = ConvertTo-SecureString "Psychi@Lab2024!" -AsPlainText -Force
Add-ADTrust -Name "moneycorp.local" -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $pass -Confirm:$false
```

### VERIFY:

```powershell
Get-ADTrust -Filter *
nltest /domain_trusts
```

**DONE.**
