# CRTP Lab Configuration - CLEAN VERSION

## What This Is

Scripts to configure the Certified Red Team Professional (CRTP) lab environment with proper forest trust between moneycorp.local and eurocorp.local domains.

## Files in This Directory

### COMPLETE AUTOMATION (Recommended):
- **CLICK-HERE-TO-START.bat** - Double-click this to automate EVERYTHING
  - Switches to correct git branch
  - Runs automation on all 3 VMs from Windows host
  - Zero manual work required

- **AUTOMATE-EVERYTHING.ps1** - Complete automation script
  - Uses VBoxManage to configure all VMs remotely
  - Run once on Windows host, configures all 3 DCs

### MANUAL METHOD (If you prefer):
- **FIX-AND-TEST.ps1** - Run manually on each DC
  - Auto-detects which DC it's running on
  - Fixes IP addresses if wrong
  - Tests everything
  - Must run on all 3 DCs (mcorp-dc, ecorp-dc, dcorp-dc)

### For GOAD Lab (Different Project):
- **Install-GOAD.ps1** - Installs Game of Active Directory lab
- **GOAD-INSTALLER-README.md** - Documentation for GOAD installer

---

## Quick Start - CRTP Lab

### Expected Setup:

```
moneycorp.local (192.168.96.10)
  └── dcorp.moneycorp.local (192.168.96.12)

eurocorp.local (192.168.96.11)

Forest Trust: moneycorp.local ↔ eurocorp.local (Bidirectional)
```

### OPTION 1: COMPLETE AUTOMATION (Easiest)

1. **On Windows Host, run ONE command:**
   ```powershell
   cd D:\Tooling\akto
   git checkout claude/powershell-game-ad-installer-sbYrr
   ```

2. **Double-click this file:**
   ```
   CLICK-HERE-TO-START.bat
   ```

   **OR run in PowerShell:**
   ```powershell
   .\AUTOMATE-EVERYTHING.ps1
   ```

That's it! The script will automatically:
- Start all VMs if needed
- Fix all IP addresses
- Configure DNS on all DCs
- Run verification tests
- Give you a complete status report

### OPTION 2: Manual Method

1. **On Windows Host:**
   ```powershell
   cd D:\Tooling
   git clone https://github.com/jnblack81/akto.git
   cd akto
   git checkout claude/powershell-game-ad-installer-sbYrr
   ```

2. **Copy script to accessible location:**
   ```powershell
   Copy-Item FIX-AND-TEST.ps1 -Destination D:\Tooling\FIX-AND-TEST.ps1
   ```

3. **Run on each DC via VirtualBox shared folder:**

   **On mcorp-dc:**
   ```powershell
   \\Vboxsvr\d_drive\Tooling\FIX-AND-TEST.ps1
   ```

   **On ecorp-dc:**
   ```powershell
   \\Vboxsvr\d_drive\Tooling\FIX-AND-TEST.ps1
   ```

   **On dcorp-dc:**
   ```powershell
   \\Vboxsvr\d_drive\Tooling\FIX-AND-TEST.ps1
   ```

### What It Does:

1. Detects which DC it's running on
2. Checks if IP address is correct:
   - mcorp-dc should be 192.168.96.10
   - ecorp-dc should be 192.168.96.11
   - dcorp-dc should be 192.168.96.12
3. Automatically fixes wrong IPs
4. Sets correct DNS servers
5. Runs 9 comprehensive tests:
   - Network connectivity
   - Domain queries
   - Forest trust verification
   - User enumeration

### Expected Result:

```
========================================
RESULTS
========================================
Passed: 9 / 9
Failed: 0 / 9

ALL TESTS PASSED - [DC-NAME] IS READY
```

---

## Troubleshooting

### Script not found / File not recognized

**The problem:** You're on the wrong git branch (probably master)

**The fix - run this ONCE:**
```powershell
cd D:\Tooling\akto
git checkout claude/powershell-game-ad-installer-sbYrr
git pull
```

Then double-click **CLICK-HERE-TO-START.bat** or run:
```powershell
.\AUTOMATE-EVERYTHING.ps1
```

### Cannot access \\Vboxsvr\d_drive
- Ensure VirtualBox Guest Additions is installed
- Verify D: drive is shared in VM settings
- Share name should be "d_drive"

### Tests failing
Run the script on ALL THREE DCs. The forest trust requires configuration on both mcorp-dc and ecorp-dc.

---

## What Was Cleaned Up

Removed 13 old/broken/duplicate scripts:
- Multiple failed verification attempts
- Duplicate configuration scripts
- Broken Python automation
- Outdated documentation

**Current working scripts:**
- AUTOMATE-EVERYTHING.ps1 - Complete automation via VBoxManage
- FIX-AND-TEST.ps1 - Manual method (run on each DC)
- CLICK-HERE-TO-START.bat - Launcher that handles git checkout and runs automation

---

## License

For CRTP training and authorized security testing only.
