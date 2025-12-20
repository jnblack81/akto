# GOAD (Game of Active Directory) Installer for VirtualBox

Automated PowerShell script to install and configure Game of Active Directory pentesting lab with all dependencies on Windows using VirtualBox.

## Overview

Game of Active Directory (GOAD) is a comprehensive Active Directory pentesting lab designed for security professionals to practice attack and defense techniques in a safe, isolated environment.

This installer automates the complete setup process, including:
- Chocolatey package manager
- Git
- VirtualBox
- Vagrant and required plugins
- WSL with Ansible
- GOAD repository and configuration

## System Requirements

### Minimum Requirements
- **OS**: Windows 10/11 (64-bit)
- **RAM**: 16 GB (32 GB recommended)
- **CPU**: 4 cores (8+ cores recommended)
- **Disk Space**: 100 GB free space
- **Virtualization**: VT-x/AMD-V enabled in BIOS
- **Hyper-V**: Must be disabled (conflicts with VirtualBox)

### Prerequisites
- Administrator access
- Stable internet connection
- PowerShell 5.1 or later

## Quick Start

### Basic Installation

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Download and run the installer**
   ```powershell
   # Navigate to the script directory
   cd C:\path\to\script

   # Run the installer
   .\Install-GOAD.ps1
   ```

3. **Wait for installation**
   - The script will install all dependencies
   - GOAD repository will be cloned to `C:\Users\<YourUsername>\GOAD`

4. **Follow post-installation instructions**

## Usage Options

### Standard Installation
```powershell
.\Install-GOAD.ps1
```

### Custom Installation Path
```powershell
.\Install-GOAD.ps1 -InstallPath "D:\MyLabs\GOAD"
```

### Choose GOAD Variant
```powershell
# Install GOAD-Light (smaller, faster)
.\Install-GOAD.ps1 -GOADVariant "GOAD-Light"

# Install full GOAD (default)
.\Install-GOAD.ps1 -GOADVariant "GOAD"

# Install SCCM variant
.\Install-GOAD.ps1 -GOADVariant "SCCM"
```

### Skip Dependency Installation
If you already have dependencies installed:
```powershell
.\Install-GOAD.ps1 -SkipDependencies
```

### Auto-Provision After Installation
```powershell
.\Install-GOAD.ps1 -AutoProvision
```

## What Gets Installed

### Package Manager
- **Chocolatey**: Windows package manager for automated installs

### Version Control
- **Git**: For cloning the GOAD repository

### Virtualization
- **VirtualBox**: Hypervisor for running virtual machines
- **Vagrant**: VM provisioning and management tool
- **Vagrant Plugins**:
  - vagrant-reload
  - vagrant-vbguest
  - winrm
  - winrm-elevated

### Automation
- **WSL (Windows Subsystem for Linux)**: Required for Ansible
- **Ubuntu for WSL**: Linux distribution
- **Ansible**: Configuration management and provisioning

### Lab Environment
- **GOAD**: Game of Active Directory lab files and configurations

## Post-Installation Steps

After the script completes, follow these steps to start the lab:

### 1. Navigate to Provider Directory
```powershell
cd "$env:USERPROFILE\GOAD\ad\GOAD\providers\virtualbox"
```

### 2. Start Virtual Machines
```powershell
vagrant up
```
This will take 1-2 hours depending on your internet speed and hardware.

### 3. Provision with Ansible

#### Option A: Using WSL (Recommended)
```powershell
# Enter WSL
wsl

# Navigate to ansible directory (adjust path for your username)
cd /mnt/c/Users/<YourUsername>/GOAD/ansible

# Run ansible playbook
ansible-playbook -i ../ad/GOAD/data/inventory -i ../ad/GOAD/providers/virtualbox/inventory main.yml
```

#### Option B: Using Windows Ansible (if available)
```powershell
cd "$env:USERPROFILE\GOAD\ansible"
ansible-playbook main.yml
```

## GOAD Variants

### GOAD (Default)
- **VMs**: 5 machines
- **Domains**: 2 domains + 1 child domain
- **Features**: Full Active Directory environment with trusts
- **RAM**: ~16-20 GB required

### GOAD-Light
- **VMs**: 3 machines
- **Domains**: 1 domain
- **Features**: Simplified AD environment
- **RAM**: ~8-12 GB required

### SCCM
- **VMs**: 6 machines
- **Domains**: Includes SCCM infrastructure
- **Features**: Full SCCM environment for testing
- **RAM**: ~20-24 GB required

## Useful Vagrant Commands

```powershell
# Check VM status
vagrant status

# Stop all VMs
vagrant halt

# Restart VMs
vagrant reload

# Destroy all VMs (clean slate)
vagrant destroy

# SSH into a specific VM
vagrant ssh <vm-name>

# Take a snapshot
vagrant snapshot save <snapshot-name>

# Restore snapshot
vagrant snapshot restore <snapshot-name>
```

## Troubleshooting

### Hyper-V Conflicts
VirtualBox cannot run while Hyper-V is enabled. Disable it:

```powershell
# Disable Hyper-V (requires restart)
bcdedit /set hypervisorlaunchtype off

# Restart computer
Restart-Computer
```

To re-enable Hyper-V later:
```powershell
bcdedit /set hypervisorlaunchtype auto
```

### Virtualization Not Enabled
Enable VT-x/AMD-V in your BIOS/UEFI settings:
1. Restart computer
2. Enter BIOS (usually F2, F10, or DEL during boot)
3. Find "Virtualization Technology" or "VT-x"
4. Enable it
5. Save and exit

### Ansible Connection Issues
If Ansible cannot connect to VMs:
```powershell
# In WSL, check connectivity
wsl
ping <vm-ip>

# Verify WinRM is working
vagrant winrm <vm-name>
```

### Insufficient Memory
If you see memory errors:
1. Close other applications
2. Use GOAD-Light variant instead
3. Modify Vagrantfile to reduce VM RAM allocation

### Network Issues
If VMs cannot connect:
```powershell
# In VirtualBox provider directory
vagrant reload

# Or recreate network
vagrant destroy
vagrant up
```

## Security Considerations

### Important Notes
- This is a **vulnerable by design** environment
- **NEVER** expose GOAD to the internet
- Use only on isolated networks or host-only networking
- For **authorized penetration testing training only**
- Reset/snapshot VMs regularly during testing

### Best Practices
1. Take snapshots before major testing
2. Use host-only or NAT networking
3. Keep GOAD isolated from production networks
4. Document all testing activities
5. Reset environment between different exercises

## Resources

### Official Documentation
- GOAD GitHub: https://github.com/Orange-Cyberdefense/GOAD
- GOAD Wiki: https://github.com/Orange-Cyberdefense/GOAD/wiki

### Tutorials
- Mayfly277's Blog: https://mayfly277.github.io/
- Active Directory Security: https://adsecurity.org/

### Prerequisites Knowledge
- Active Directory fundamentals
- Windows administration
- Basic networking
- Penetration testing basics

## Lab Contents

### Default GOAD Environment Includes:
- Multiple Windows Server domains
- Active Directory Certificate Services (ADCS)
- Microsoft SQL Server
- Various misconfigurations and vulnerabilities:
  - Kerberoasting opportunities
  - AS-REP Roasting
  - Unconstrained/Constrained Delegation
  - NTLM Relay paths
  - GPO misconfigurations
  - ACL abuse paths
  - And much more!

## Getting Help

### Script Issues
- Check PowerShell execution policy: `Get-ExecutionPolicy`
- Run with verbose output: `.\Install-GOAD.ps1 -Verbose`
- Check logs in `$env:TEMP`

### GOAD Issues
- Check GOAD GitHub Issues: https://github.com/Orange-Cyberdefense/GOAD/issues
- Review GOAD documentation
- Join security communities (Discord, Reddit r/AskNetsec)

## Uninstalling

### Remove GOAD VMs
```powershell
cd "$env:USERPROFILE\GOAD\ad\GOAD\providers\virtualbox"
vagrant destroy -f
```

### Remove GOAD Files
```powershell
Remove-Item -Path "$env:USERPROFILE\GOAD" -Recurse -Force
```

### Uninstall Dependencies (Optional)
```powershell
choco uninstall virtualbox vagrant git -y
```

## License

This installer script is provided as-is for educational purposes.

GOAD is created by Orange Cyberdefense and licensed under GPLv3.

## Disclaimer

This lab environment contains intentional security vulnerabilities and should only be used for authorized security training and research. The authors are not responsible for any misuse of this tool.

**Use responsibly and legally!**

## Support

For issues with this installer script, please open an issue on the repository.

For GOAD-specific issues, refer to the official GOAD repository.

---

**Happy Hacking! (Legally and Ethically)** 🎯🔐
