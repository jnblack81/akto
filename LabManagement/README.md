# CRTP Lab Management Scripts

Complete lab management automation for the Certified Red Team Professional (CRTP) lab environment.

## Overview

These scripts automate the management of all 10 VMs in the CRTP lab:
- **3 Domain Controllers**: mcorp-dc, ecorp-dc, dcorp-dc
- **7 Member Servers**: dcorp-adminsrv, dcorp-appsrv, dcorp-ci, dcorp-mgmt, dcorp-mssql, dcorp-sql1, dcorp-stdadmin

## Scripts

### 1. Start-CRTPLab.ps1
**Purpose**: Start all VMs in the correct order (DCs first, then member servers)

**Usage**:
```powershell
# Start with GUI
.\Start-CRTPLab.ps1

# Start in headless mode (no GUI)
.\Start-CRTPLab.ps1 -Headless
```

**What it does**:
- Checks VM status
- Starts Domain Controllers first
- Waits 60 seconds for DCs to boot
- Starts member servers
- Shows final status of all VMs

---

### 2. Stop-CRTPLab.ps1
**Purpose**: Gracefully shutdown all VMs (member servers first, then DCs)

**Usage**:
```powershell
# Graceful ACPI shutdown
.\Stop-CRTPLab.ps1

# Force immediate shutdown
.\Stop-CRTPLab.ps1 -Force
```

**What it does**:
- Shuts down member servers first
- Waits for graceful shutdown (unless -Force is used)
- Shuts down Domain Controllers
- Verifies all VMs stopped

---

### 3. Snapshot-CRTPLab.ps1
**Purpose**: Take snapshots of all 10 VMs with timestamp

**Usage**:
```powershell
# Auto-named snapshot with timestamp
.\Snapshot-CRTPLab.ps1

# Custom snapshot name
.\Snapshot-CRTPLab.ps1 -SnapshotName "Before-Lab14" -Description "Clean state before Lab 14"

# Quick baseline snapshot
.\Snapshot-CRTPLab.ps1 -SnapshotName "Baseline-Working" -Description "Fully configured and tested"
```

**What it does**:
- Creates identical snapshots across all 10 VMs
- Adds timestamp if no name provided
- Works on running or stopped VMs
- Shows snapshot creation results

**Recommended snapshots**:
- `Baseline-Working` - After initial configuration, all tests passing
- `Before-LabXX` - Before starting each CRTP lab exercise
- `After-LabXX-Success` - After successfully completing a lab

---

### 4. Test-CRTPLab.ps1
**Purpose**: Test network connectivity and services across all VMs

**Usage**:
```powershell
.\Test-CRTPLab.ps1
```

**What it tests**:
- VM running status (all 10 VMs)
- Network connectivity (ping all IPs)
- Critical ports:
  - DCs: 53 (DNS), 88 (Kerberos), 389 (LDAP), 445 (SMB)
  - SQL servers: 1433 (MSSQL)
  - Workstations: 3389 (RDP), 445 (SMB)
  - App servers: 80, 443, 8080
- DNS resolution for all domains
- Forest trust (moneycorp <-> eurocorp)

**Expected result**: All tests should pass for a healthy lab

---

### 5. Test-CRTPVulnerabilities.ps1
**Purpose**: Verify CRTP-specific vulnerabilities are deployed

**Usage**:
```powershell
.\Test-CRTPVulnerabilities.ps1
```

**What it checks**:
- **Lab 14**: Kerberoastable service accounts
- **Lab 15**: AS-REP roastable accounts
- **Lab 16**: Unconstrained delegation
- **Lab 17**: Constrained delegation
- **Lab 18**: Resource-based constrained delegation
- **Lab 19**: SQL Server linked servers
- **Lab 20**: Forest trust (moneycorp <-> eurocorp)
- **Lab 21**: Domain trust (dollarcorp -> moneycorp)
- **Lab 22**: ACL misconfigurations
- **Lab 23**: MSSQL server access
- **Infrastructure**: Student workstation RDP access

**Note**: Some checks may show "UNKNOWN" if run from outside the lab. Run from dcorp-stdadmin for best results.

---

### 6. Restore-CRTPLab.ps1
**Purpose**: Revert all VMs to a previous snapshot

**Usage**:
```powershell
# List available snapshots
.\Restore-CRTPLab.ps1 -ListSnapshots

# Restore to latest snapshot
.\Restore-CRTPLab.ps1 -Latest

# Restore to specific snapshot
.\Restore-CRTPLab.ps1 -SnapshotName "Baseline-Working"

# Restore to before Lab 14
.\Restore-CRTPLab.ps1 -SnapshotName "Before-Lab14"
```

**What it does**:
- Lists snapshots (if -ListSnapshots)
- Confirms restore operation (requires typing "YES")
- Shuts down all running VMs
- Restores all VMs to specified snapshot
- Shows restore results

**⚠️ WARNING**: All changes after the snapshot will be LOST!

---

## Typical Workflows

### Daily Lab Startup
```powershell
# Start the lab
.\Start-CRTPLab.ps1

# Verify everything is working
.\Test-CRTPLab.ps1
```

### Before Starting a New Lab Exercise
```powershell
# Take snapshot before Lab 14
.\Snapshot-CRTPLab.ps1 -SnapshotName "Before-Lab14" -Description "Clean state before Kerberoasting lab"

# Start working on lab...
```

### After Breaking Something
```powershell
# Check what's broken
.\Test-CRTPLab.ps1

# Restore to last known good state
.\Restore-CRTPLab.ps1 -SnapshotName "Baseline-Working"

# Restart the lab
.\Start-CRTPLab.ps1
```

### End of Day Shutdown
```powershell
# Graceful shutdown
.\Stop-CRTPLab.ps1
```

### Creating a Clean Baseline
```powershell
# 1. Start lab
.\Start-CRTPLab.ps1

# 2. Verify all tests pass
.\Test-CRTPLab.ps1

# 3. If all good, take baseline snapshot
.\Snapshot-CRTPLab.ps1 -SnapshotName "Baseline-Working" -Description "All DCs configured, all tests passing"

# 4. Shutdown
.\Stop-CRTPLab.ps1
```

---

## VM Network Information

| VM Name | IP Address | Role | Domain |
|---------|------------|------|--------|
| mcorp-dc | 192.168.96.10 | Domain Controller | moneycorp.local |
| ecorp-dc | 192.168.96.100 | Domain Controller | eurocorp.local |
| dcorp-dc | 192.168.96.20 | Domain Controller | dcorp.moneycorp.local |
| dcorp-adminsrv | 192.168.96.21 | Admin Server | dcorp.moneycorp.local |
| dcorp-appsrv | 192.168.96.22 | App Server | dcorp.moneycorp.local |
| dcorp-ci | 192.168.96.23 | CI Server | dcorp.moneycorp.local |
| dcorp-mgmt | 192.168.96.24 | Management Server | dcorp.moneycorp.local |
| dcorp-mssql | 192.168.96.25 | SQL Server | dcorp.moneycorp.local |
| dcorp-sql1 | 192.168.96.26 | SQL Server | dcorp.moneycorp.local |
| dcorp-stdadmin | 192.168.96.50 | Student Workstation | dcorp.moneycorp.local |

---

## Credentials

### Domain Administrator Accounts
- **moneycorp.local**: `moneycorp\Administrator` / `Psychi@Lab2024!`
- **eurocorp.local**: `eurocorp\Administrator` / `Psychi@Lab2024!`
- **dcorp.moneycorp.local**: `dollarcorp\Administrator` / `Psychi@Lab2024!`

### Student Account
- **dcorp-stdadmin**: `dollarcorp\student` / `Password123!`

---

## Troubleshooting

### VMs won't start
```powershell
# Check VM status
VBoxManage list vms
VBoxManage list runningvms

# Try starting individual VM
VBoxManage startvm mcorp-dc --type gui
```

### Tests are failing
```powershell
# Run FIX-AND-TEST.ps1 inside each DC
# From host, copy to shared folder:
# Then RDP to each DC and run: \\vboxsvr\d_drive\Tooling\akto\FIX-AND-TEST.ps1
```

### Snapshot restore failed
```powershell
# List snapshots for specific VM
VBoxManage snapshot mcorp-dc list

# Manually restore single VM
VBoxManage snapshot mcorp-dc restore "Baseline-Working"
```

---

## Additional Resources

- **FIX-AND-TEST.ps1**: Run inside each DC to verify configuration
- **VERIFY-CRTP-COMPLETE.ps1**: Comprehensive 36-point verification script
- **AUTOMATE-EVERYTHING.ps1**: Initial lab setup automation

---

## Support

For issues or questions:
1. Check VM status with `Test-CRTPLab.ps1`
2. Run `FIX-AND-TEST.ps1` inside problematic VMs
3. Review logs in VirtualBox GUI
4. Restore to last known good snapshot

---

**Created**: 2024-01-24
**CRTP Lab Version**: 2024
