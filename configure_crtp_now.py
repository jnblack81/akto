#!/usr/bin/env python3
"""
CRTP Lab Auto-Configuration Script
Connects to domain controllers and configures forest trust
"""

import subprocess
import sys
import socket
import time

print("=" * 60)
print("CRTP LAB AUTO-CONFIGURATION")
print("=" * 60)
print()

# Configuration
MCORP_DC = "192.168.96.10"
ECORP_DC = "192.168.96.11"
MCORP_DOMAIN = "moneycorp.local"
ECORP_DOMAIN = "eurocorp.local"
PASSWORD = "Psychi@Lab2024!"

def test_connectivity(host, port=5985):
    """Test if host is reachable"""
    print(f"[*] Testing connectivity to {host}:{port}...")
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        if result == 0:
            print(f"[+] {host} is reachable on port {port}")
            return True
        else:
            print(f"[-] {host} is NOT reachable on port {port}")
            return False
    except Exception as e:
        print(f"[-] Error testing {host}: {e}")
        return False

def install_winrm():
    """Install pywinrm for remote PowerShell"""
    print("[*] Installing pywinrm...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "pywinrm"])
        print("[+] pywinrm installed")
        return True
    except Exception as e:
        print(f"[-] Failed to install pywinrm: {e}")
        return False

def configure_mcorp_dc():
    """Configure moneycorp.local forest trust"""
    print()
    print("=" * 60)
    print("CONFIGURING MCORP-DC (moneycorp.local)")
    print("=" * 60)
    print()

    try:
        import winrm

        # Connect to mcorp-dc
        print(f"[*] Connecting to {MCORP_DC}...")
        session = winrm.Session(
            f'http://{MCORP_DC}:5985/wsman',
            auth=(f'{MCORP_DOMAIN}\\Administrator', PASSWORD),
            transport='ntlm'
        )

        # Test connection
        result = session.run_ps('$env:COMPUTERNAME')
        if result.status_code == 0:
            print(f"[+] Connected to: {result.std_out.decode().strip()}")
        else:
            print(f"[-] Connection failed: {result.std_err.decode()}")
            return False

        # Configure DNS forwarder
        print("[*] Configuring DNS forwarder for eurocorp.local...")
        dns_cmd = """
        $forwarder = Get-DnsServerZone -Name 'eurocorp.local' -ErrorAction SilentlyContinue
        if (-not $forwarder) {
            Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11
            Write-Host 'DNS forwarder created'
        } else {
            Write-Host 'DNS forwarder exists'
        }
        """
        result = session.run_ps(dns_cmd)
        print(result.std_out.decode())

        # Remove existing broken trust
        print("[*] Removing any existing broken trust...")
        remove_trust_cmd = """
        Remove-ADTrust -Identity 'eurocorp.local' -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Write-Host 'Trust removed (if it existed)'
        """
        result = session.run_ps(remove_trust_cmd)
        print(result.std_out.decode())

        # Create forest trust
        print("[*] Creating bidirectional forest trust...")
        create_trust_cmd = f"""
        $trustPassword = ConvertTo-SecureString '{PASSWORD}' -AsPlainText -Force

        Add-ADTrust `
            -Name 'eurocorp.local' `
            -TrustType Forest `
            -TrustDirection Bidirectional `
            -ForestTransitive $true `
            -TrustPassword $trustPassword `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host 'Forest trust created successfully!'
        """
        result = session.run_ps(create_trust_cmd)
        if result.status_code == 0:
            print("[+] " + result.std_out.decode())
        else:
            print(f"[-] Error: {result.std_err.decode()}")
            return False

        # Verify trust
        print("[*] Verifying trust...")
        verify_cmd = """
        $trust = Get-ADTrust -Filter "Target -eq 'eurocorp.local'"
        if ($trust) {
            Write-Host "Trust verified: $($trust.Name) - $($trust.Direction) - $($trust.TrustType)"
        } else {
            Write-Host "Trust verification failed!"
        }
        """
        result = session.run_ps(verify_cmd)
        print(result.std_out.decode())

        print()
        print("[+] MCORP-DC configuration complete!")
        return True

    except ImportError:
        print("[-] pywinrm not available")
        return False
    except Exception as e:
        print(f"[-] Error configuring mcorp-dc: {e}")
        return False

def configure_ecorp_dc():
    """Configure eurocorp.local forest trust"""
    print()
    print("=" * 60)
    print("CONFIGURING ECORP-DC (eurocorp.local)")
    print("=" * 60)
    print()

    try:
        import winrm

        # Connect to ecorp-dc
        print(f"[*] Connecting to {ECORP_DC}...")
        session = winrm.Session(
            f'http://{ECORP_DC}:5985/wsman',
            auth=(f'{ECORP_DOMAIN}\\Administrator', PASSWORD),
            transport='ntlm'
        )

        # Test connection
        result = session.run_ps('$env:COMPUTERNAME')
        if result.status_code == 0:
            print(f"[+] Connected to: {result.std_out.decode().strip()}")
        else:
            print(f"[-] Connection failed: {result.std_err.decode()}")
            return False

        # Configure DNS forwarder
        print("[*] Configuring DNS forwarder for moneycorp.local...")
        dns_cmd = """
        $forwarder = Get-DnsServerZone -Name 'moneycorp.local' -ErrorAction SilentlyContinue
        if (-not $forwarder) {
            Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10
            Write-Host 'DNS forwarder created'
        } else {
            Write-Host 'DNS forwarder exists'
        }
        """
        result = session.run_ps(dns_cmd)
        print(result.std_out.decode())

        # Remove existing broken trust
        print("[*] Removing any existing broken trust...")
        remove_trust_cmd = """
        Remove-ADTrust -Identity 'moneycorp.local' -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Write-Host 'Trust removed (if it existed)'
        """
        result = session.run_ps(remove_trust_cmd)
        print(result.std_out.decode())

        # Create forest trust
        print("[*] Creating bidirectional forest trust...")
        create_trust_cmd = f"""
        $trustPassword = ConvertTo-SecureString '{PASSWORD}' -AsPlainText -Force

        Add-ADTrust `
            -Name 'moneycorp.local' `
            -TrustType Forest `
            -TrustDirection Bidirectional `
            -ForestTransitive $true `
            -TrustPassword $trustPassword `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host 'Forest trust created successfully!'
        """
        result = session.run_ps(create_trust_cmd)
        if result.status_code == 0:
            print("[+] " + result.std_out.decode())
        else:
            print(f"[-] Error: {result.std_err.decode()}")
            return False

        # Verify trust
        print("[*] Verifying trust...")
        verify_cmd = """
        $trust = Get-ADTrust -Filter "Target -eq 'moneycorp.local'"
        if ($trust) {
            Write-Host "Trust verified: $($trust.Name) - $($trust.Direction) - $($trust.TrustType)"
        } else {
            Write-Host "Trust verification failed!"
        }
        """
        result = session.run_ps(verify_cmd)
        print(result.std_out.decode())

        print()
        print("[+] ECORP-DC configuration complete!")
        return True

    except ImportError:
        print("[-] pywinrm not available")
        return False
    except Exception as e:
        print(f"[-] Error configuring ecorp-dc: {e}")
        return False

def main():
    """Main execution"""

    # Test connectivity
    mcorp_reachable = test_connectivity(MCORP_DC)
    ecorp_reachable = test_connectivity(ECORP_DC)

    if not (mcorp_reachable or ecorp_reachable):
        print()
        print("[-] Cannot reach any domain controllers!")
        print("[-] Check VirtualBox network configuration")
        print("[-] Ensure VMs are running and WinRM is enabled")
        return False

    # Install winrm if needed
    print()
    if not install_winrm():
        print("[-] Cannot install pywinrm")
        print("[-] Falling back to script generation only")
        return False

    # Configure mcorp-dc
    if mcorp_reachable:
        if not configure_mcorp_dc():
            print("[-] Failed to configure mcorp-dc")
    else:
        print("[!] Skipping mcorp-dc (not reachable)")

    print()
    time.sleep(2)

    # Configure ecorp-dc
    if ecorp_reachable:
        if not configure_ecorp_dc():
            print("[-] Failed to configure ecorp-dc")
    else:
        print("[!] Skipping ecorp-dc (not reachable)")

    # Final summary
    print()
    print("=" * 60)
    print("CONFIGURATION COMPLETE!")
    print("=" * 60)
    print()
    print("Forest trust configured between:")
    print("  - moneycorp.local")
    print("  - eurocorp.local")
    print()
    print("Verify with:")
    print("  Get-ADTrust -Filter *")
    print()

    return True

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[!] Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n[!] Fatal error: {e}")
        sys.exit(1)
