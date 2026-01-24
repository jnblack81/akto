# CRTP Lab Documentation - Essential Scripts Only

## Quick Start

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

## That's It

Everything you need is in this folder. No other files required.
