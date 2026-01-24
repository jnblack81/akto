# CRTP Lab Documentation - Essential Scripts Only

## IMPORTANT: First Time Setup

**Before running tests from the host**, you need to configure Windows Firewall on each VM to allow host access.

### One-Time Firewall Setup (Run on EACH VM)

1. **RDP to each VM** (or use VirtualBox console)
2. **Run this command inside each VM**:
```powershell
\\vboxsvr\e_drive\Lab-documentation\ENABLE-HOST-ACCESS.ps1
```

**Do this for all 10 VMs:**
- mcorp-dc (192.168.96.10)
- ecorp-dc (192.168.96.100)
- dcorp-dc (192.168.96.20)
- dcorp-adminsrv (192.168.96.21)
- dcorp-appsrv (192.168.96.22)
- dcorp-ci (192.168.96.23)
- dcorp-mgmt (192.168.96.24)
- dcorp-mssql (192.168.96.25)
- dcorp-sql1 (192.168.96.26)
- dcorp-stdadmin (192.168.96.50)

This opens firewall ports so the host can run tests and connect to services.

---

## Quick Start (After Firewall Setup)

### 1. Start Lab
```powershell
.\LabManagement\Start-CRTPLab.ps1
```

### 2. Test Lab
```powershell
.\LabManagement\Test-CRTPLab.ps1
```

### 3. Fix DCs (run inside each DC via RDP)
```powershell
# From inside mcorp-dc, ecorp-dc, or dcorp-dc:
\\vboxsvr\e_drive\Lab-documentation\FIX-AND-TEST.ps1
```

---

## All Scripts

### Host Scripts (run from Windows PowerShell on E:\Lab-documentation)

| Script | Purpose |
|--------|---------|
| **LAB-MANAGER.ps1** | Interactive menu launcher |
| **ENABLE-HOST-ACCESS.ps1** | Enable firewall rules (run ONCE on each VM) |
| **LabManagement/Start-CRTPLab.ps1** | Start all 10 VMs |
| **LabManagement/Stop-CRTPLab.ps1** | Stop all 10 VMs |
| **LabManagement/Test-CRTPLab.ps1** | Test connectivity & services |
| **LabManagement/Snapshot-CRTPLab.ps1** | Take snapshots of all VMs |
| **LabManagement/Restore-CRTPLab.ps1** | Restore VMs to snapshot |
| **LabManagement/Test-CRTPVulnerabilities.ps1** | Check CRTP vulns deployed |

### VM Scripts (run inside VMs via RDP)

| Script | Purpose | Run On |
|--------|---------|--------|
| **FIX-AND-TEST.ps1** | Fix IPs, DNS, test everything | Each DC (mcorp-dc, ecorp-dc, dcorp-dc) |

---

## Daily Workflow

```powershell
# 1. Start lab
.\LabManagement\Start-CRTPLab.ps1

# 2. Verify connectivity
.\LabManagement\Test-CRTPLab.ps1

# 3. If issues, RDP to DCs and run:
\\vboxsvr\e_drive\Lab-documentation\FIX-AND-TEST.ps1
```

---

## Snapshot Workflow

```powershell
# Take baseline snapshot
.\LabManagement\Snapshot-CRTPLab.ps1 -SnapshotName "Baseline"

# Before lab exercise
.\LabManagement\Snapshot-CRTPLab.ps1 -SnapshotName "Before-Lab14"

# Restore if broken
.\LabManagement\Restore-CRTPLab.ps1 -SnapshotName "Baseline"
```

---

## VM Information

| VM | IP | Role | Credentials |
|----|----|----|-------------|
| mcorp-dc | 192.168.96.10 | DC | moneycorp\Administrator : Psychi@Lab2024! |
| ecorp-dc | 192.168.96.100 | DC | eurocorp\Administrator : Psychi@Lab2024! |
| dcorp-dc | 192.168.96.20 | DC | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-adminsrv | 192.168.96.21 | Server | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-appsrv | 192.168.96.22 | Server | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-ci | 192.168.96.23 | Server | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-mgmt | 192.168.96.24 | Server | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-mssql | 192.168.96.25 | SQL | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-sql1 | 192.168.96.26 | SQL | dollarcorp\Administrator : Psychi@Lab2024! |
| dcorp-stdadmin | 192.168.96.50 | Workstation | dollarcorp\student : Password123! |

---

## Troubleshooting

### Tests failing with "connection refused"
- Run `ENABLE-HOST-ACCESS.ps1` on each VM to open firewall ports

### VMs not starting
```powershell
VBoxManage startvm <vm-name> --type gui
```

### DNS issues
- RDP to each DC and run `FIX-AND-TEST.ps1`

---

## That's It

Everything you need is in this folder. No other files required.
