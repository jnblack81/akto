<#
.SYNOPSIS
    Game of Active Directory (GOAD) Installation Script for VirtualBox
.DESCRIPTION
    This script automates the installation of Game of Active Directory (GOAD)
    pentesting lab environment with all required dependencies on Windows using VirtualBox.
.NOTES
    Author: Akto Security
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
    Run as: Administrator
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "$env:USERPROFILE\GOAD",

    [Parameter(Mandatory=$false)]
    [ValidateSet("GOAD", "GOAD-Light", "SCCM")]
    [string]$GOADVariant = "GOAD",

    [Parameter(Mandatory=$false)]
    [switch]$SkipDependencies,

    [Parameter(Mandatory=$false)]
    [switch]$AutoProvision
)

# Requires administrator privileges
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Color output functions
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Success", "Error", "Warning", "Info")]
        [string]$Type = "Info"
    )

    $color = switch($Type) {
        "Success" { "Green" }
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Info" { "Cyan" }
    }

    Write-Host "[$Type] $Message" -ForegroundColor $color
}

# Banner
function Show-Banner {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Game of Active Directory (GOAD) Installer                  ║
║   VirtualBox + Vagrant + Ansible Setup                       ║
║                                                               ║
║   This script will install all dependencies and setup GOAD   ║
║   pentesting lab environment on your local machine.          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    Write-Host ""
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if Chocolatey is installed
function Test-Chocolatey {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Install Chocolatey
function Install-Chocolatey {
    Write-ColorOutput "Installing Chocolatey package manager..." -Type Info

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-ColorOutput "Chocolatey installed successfully!" -Type Success
        return $true
    }
    catch {
        Write-ColorOutput "Failed to install Chocolatey: $_" -Type Error
        return $false
    }
}

# Check if a program is installed
function Test-ProgramInstalled {
    param([string]$ProgramName)

    $installed = $false

    # Check via Chocolatey
    try {
        $chocoList = choco list --local-only $ProgramName 2>$null
        if ($chocoList -match $ProgramName) {
            $installed = $true
        }
    }
    catch { }

    # Check via command
    if (-not $installed) {
        try {
            $null = Get-Command $ProgramName -ErrorAction Stop
            $installed = $true
        }
        catch { }
    }

    return $installed
}

# Install dependencies via Chocolatey
function Install-Dependencies {
    Write-ColorOutput "Installing required dependencies..." -Type Info

    $dependencies = @(
        @{Name="git"; Package="git.install"; Command="git"},
        @{Name="VirtualBox"; Package="virtualbox"; Command="vboxmanage"},
        @{Name="Vagrant"; Package="vagrant"; Command="vagrant"}
    )

    foreach ($dep in $dependencies) {
        Write-ColorOutput "Checking $($dep.Name)..." -Type Info

        if (Test-ProgramInstalled $dep.Command) {
            Write-ColorOutput "$($dep.Name) is already installed." -Type Success
        }
        else {
            Write-ColorOutput "Installing $($dep.Name)..." -Type Info
            try {
                choco install $dep.Package -y --no-progress
                Write-ColorOutput "$($dep.Name) installed successfully!" -Type Success
            }
            catch {
                Write-ColorOutput "Failed to install $($dep.Name): $_" -Type Error
                return $false
            }
        }
    }

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Write-ColorOutput "All dependencies installed successfully!" -Type Success
    return $true
}

# Install Vagrant plugins
function Install-VagrantPlugins {
    Write-ColorOutput "Installing required Vagrant plugins..." -Type Info

    $plugins = @(
        "vagrant-reload",
        "vagrant-vbguest",
        "winrm",
        "winrm-elevated"
    )

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    foreach ($plugin in $plugins) {
        Write-ColorOutput "Installing Vagrant plugin: $plugin..." -Type Info
        try {
            & vagrant plugin install $plugin 2>&1 | Out-Null
            Write-ColorOutput "Plugin $plugin installed!" -Type Success
        }
        catch {
            Write-ColorOutput "Warning: Failed to install plugin $plugin - $_" -Type Warning
        }
    }
}

# Setup WSL for Ansible
function Install-WSLAnsible {
    Write-ColorOutput "Setting up WSL for Ansible..." -Type Info

    # Check if WSL is enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    if ($wslFeature.State -ne "Enabled") {
        Write-ColorOutput "Enabling WSL..." -Type Info
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            Write-ColorOutput "WSL enabled. You may need to restart your computer." -Type Warning
        }
        catch {
            Write-ColorOutput "Failed to enable WSL: $_" -Type Error
            Write-ColorOutput "You can install Ansible manually in WSL or use ansible-core for Windows" -Type Info
            return $false
        }
    }

    # Check if Ubuntu is installed
    try {
        $ubuntuInstalled = wsl --list 2>$null | Select-String -Pattern "Ubuntu"

        if (-not $ubuntuInstalled) {
            Write-ColorOutput "Installing Ubuntu for WSL..." -Type Info
            choco install wsl-ubuntu-2204 -y --no-progress
        }

        Write-ColorOutput "Installing Ansible in WSL..." -Type Info
        wsl -e bash -c "sudo apt update && sudo apt install -y ansible sshpass python3-pip"

        Write-ColorOutput "Ansible installed in WSL!" -Type Success
        return $true
    }
    catch {
        Write-ColorOutput "WSL setup encountered issues: $_" -Type Warning
        Write-ColorOutput "You may need to install Ansible manually" -Type Info
        return $false
    }
}

# Clone GOAD repository
function Get-GOADRepository {
    param([string]$Path)

    Write-ColorOutput "Cloning GOAD repository..." -Type Info

    if (Test-Path $Path) {
        Write-ColorOutput "GOAD directory already exists at $Path" -Type Warning
        $response = Read-Host "Do you want to delete and re-clone? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Remove-Item -Path $Path -Recurse -Force
        }
        else {
            Write-ColorOutput "Using existing GOAD directory." -Type Info
            return $true
        }
    }

    try {
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $parentPath = Split-Path -Parent $Path
        if (-not (Test-Path $parentPath)) {
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }

        Set-Location $parentPath
        & git clone https://github.com/Orange-Cyberdefense/GOAD.git (Split-Path -Leaf $Path)

        Write-ColorOutput "GOAD repository cloned successfully!" -Type Success
        return $true
    }
    catch {
        Write-ColorOutput "Failed to clone GOAD repository: $_" -Type Error
        return $false
    }
}

# Configure GOAD for VirtualBox
function Set-GOADConfiguration {
    param(
        [string]$Path,
        [string]$Variant
    )

    Write-ColorOutput "Configuring GOAD for VirtualBox provider..." -Type Info

    $providerPath = Join-Path $Path "ad\$Variant\providers\virtualbox"

    if (-not (Test-Path $providerPath)) {
        Write-ColorOutput "Provider path not found: $providerPath" -Type Error
        return $false
    }

    Set-Location $providerPath
    Write-ColorOutput "GOAD configured! Location: $providerPath" -Type Success
    return $true
}

# Display post-installation instructions
function Show-PostInstallInstructions {
    param(
        [string]$Path,
        [string]$Variant
    )

    $providerPath = Join-Path $Path "ad\$Variant\providers\virtualbox"

    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Type Success
    Write-ColorOutput "Installation completed successfully!" -Type Success
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Type Success
    Write-Host ""

    Write-Host "GOAD Location: " -NoNewline
    Write-Host $Path -ForegroundColor Yellow
    Write-Host "Provider Path: " -NoNewline
    Write-Host $providerPath -ForegroundColor Yellow
    Write-Host ""

    Write-ColorOutput "Next Steps:" -Type Info
    Write-Host ""
    Write-Host "1. Navigate to the provider directory:" -ForegroundColor White
    Write-Host "   cd `"$providerPath`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Start the lab (this will take 1-2 hours):" -ForegroundColor White
    Write-Host "   vagrant up" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. After VMs are up, provision with Ansible:" -ForegroundColor White
    Write-Host "   Using WSL:" -ForegroundColor Gray
    Write-Host "   wsl" -ForegroundColor Gray
    Write-Host "   cd /mnt/c/Users/<your-username>/GOAD/ansible" -ForegroundColor Gray
    Write-Host "   ansible-playbook -i ../ad/$Variant/data/inventory -i ../ad/$Variant/providers/virtualbox/inventory main.yml" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   OR using Windows (if ansible-playbook is available):" -ForegroundColor Gray
    Write-Host "   cd `"$Path\ansible`"" -ForegroundColor Gray
    Write-Host "   ansible-playbook main.yml" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Useful Vagrant commands:" -ForegroundColor White
    Write-Host "   vagrant status          - Check VM status" -ForegroundColor Gray
    Write-Host "   vagrant halt            - Stop all VMs" -ForegroundColor Gray
    Write-Host "   vagrant destroy         - Delete all VMs" -ForegroundColor Gray
    Write-Host "   vagrant snapshot save   - Save VM state" -ForegroundColor Gray
    Write-Host ""

    Write-ColorOutput "Documentation: https://github.com/Orange-Cyberdefense/GOAD" -Type Info
    Write-Host ""
    Write-ColorOutput "Important: Ensure Hyper-V is disabled if you encounter VirtualBox issues!" -Type Warning
    Write-Host "   Run: bcdedit /set hypervisorlaunchtype off" -ForegroundColor Gray
    Write-Host "   Then restart your computer" -ForegroundColor Gray
    Write-Host ""
}

# Provision GOAD automatically
function Start-GOADProvisioning {
    param(
        [string]$Path,
        [string]$Variant
    )

    $providerPath = Join-Path $Path "ad\$Variant\providers\virtualbox"

    Write-ColorOutput "Starting GOAD provisioning..." -Type Info
    Write-ColorOutput "This will take 1-2 hours. Please be patient..." -Type Warning

    Set-Location $providerPath

    try {
        Write-ColorOutput "Starting Vagrant VMs..." -Type Info
        & vagrant up

        Write-ColorOutput "VMs started! Now running Ansible provisioning..." -Type Info

        # Try WSL ansible first
        $ansiblePath = Join-Path $Path "ansible"
        $inventoryPath = Join-Path $Path "ad\$Variant\data\inventory"

        wsl -e bash -c "cd '$ansiblePath' && ansible-playbook -i '$inventoryPath' main.yml"

        Write-ColorOutput "GOAD provisioning completed!" -Type Success
    }
    catch {
        Write-ColorOutput "Provisioning encountered errors: $_" -Type Error
        Write-ColorOutput "You may need to provision manually. See instructions above." -Type Warning
    }
}

# Main installation process
function Start-Installation {
    Show-Banner

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-ColorOutput "This script must be run as Administrator!" -Type Error
        Write-ColorOutput "Please restart PowerShell as Administrator and try again." -Type Error
        exit 1
    }

    Write-ColorOutput "Installation Path: $InstallPath" -Type Info
    Write-ColorOutput "GOAD Variant: $GOADVariant" -Type Info
    Write-Host ""

    if (-not $SkipDependencies) {
        # Install Chocolatey if needed
        if (-not (Test-Chocolatey)) {
            if (-not (Install-Chocolatey)) {
                Write-ColorOutput "Failed to install Chocolatey. Exiting." -Type Error
                exit 1
            }
        }
        else {
            Write-ColorOutput "Chocolatey is already installed." -Type Success
        }

        # Install dependencies
        if (-not (Install-Dependencies)) {
            Write-ColorOutput "Failed to install dependencies. Exiting." -Type Error
            exit 1
        }

        # Install Vagrant plugins
        Install-VagrantPlugins

        # Setup Ansible
        Install-WSLAnsible
    }
    else {
        Write-ColorOutput "Skipping dependency installation..." -Type Warning
    }

    # Clone GOAD repository
    if (-not (Get-GOADRepository -Path $InstallPath)) {
        Write-ColorOutput "Failed to clone GOAD repository. Exiting." -Type Error
        exit 1
    }

    # Configure GOAD
    if (-not (Set-GOADConfiguration -Path $InstallPath -Variant $GOADVariant)) {
        Write-ColorOutput "Failed to configure GOAD. Exiting." -Type Error
        exit 1
    }

    # Show instructions
    Show-PostInstallInstructions -Path $InstallPath -Variant $GOADVariant

    # Auto-provision if requested
    if ($AutoProvision) {
        $response = Read-Host "Do you want to start provisioning now? This will take 1-2 hours (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Start-GOADProvisioning -Path $InstallPath -Variant $GOADVariant
        }
    }
}

# Run installation
try {
    Start-Installation
}
catch {
    Write-ColorOutput "Installation failed with error: $_" -Type Error
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}
