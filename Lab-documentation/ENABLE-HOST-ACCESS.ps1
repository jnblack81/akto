# ========================================
# ENABLE HOST ACCESS TO VM
# Run this ONCE on each VM to allow host connectivity
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ENABLE HOST ACCESS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$hostname = $env:COMPUTERNAME
Write-Host "Configuring firewall on: $hostname" -ForegroundColor Yellow
Write-Host ""

# Enable firewall rules for common services
$rules = @(
    @{Name="DNS-TCP-In"; DisplayName="DNS (TCP-In) from Host"; Protocol="TCP"; Port=53},
    @{Name="DNS-UDP-In"; DisplayName="DNS (UDP-In) from Host"; Protocol="UDP"; Port=53},
    @{Name="Kerberos-TCP-In"; DisplayName="Kerberos (TCP-In) from Host"; Protocol="TCP"; Port=88},
    @{Name="Kerberos-UDP-In"; DisplayName="Kerberos (UDP-In) from Host"; Protocol="UDP"; Port=88},
    @{Name="LDAP-TCP-In"; DisplayName="LDAP (TCP-In) from Host"; Protocol="TCP"; Port=389},
    @{Name="LDAP-UDP-In"; DisplayName="LDAP (UDP-In) from Host"; Protocol="UDP"; Port=389},
    @{Name="SMB-TCP-In"; DisplayName="SMB (TCP-In) from Host"; Protocol="TCP"; Port=445},
    @{Name="RPC-TCP-In"; DisplayName="RPC (TCP-In) from Host"; Protocol="TCP"; Port=135},
    @{Name="RDP-TCP-In"; DisplayName="RDP (TCP-In) from Host"; Protocol="TCP"; Port=3389},
    @{Name="WinRM-HTTP-In"; DisplayName="WinRM HTTP (TCP-In) from Host"; Protocol="TCP"; Port=5985},
    @{Name="WinRM-HTTPS-In"; DisplayName="WinRM HTTPS (TCP-In) from Host"; Protocol="TCP"; Port=5986},
    @{Name="MSSQL-TCP-In"; DisplayName="MSSQL (TCP-In) from Host"; Protocol="TCP"; Port=1433},
    @{Name="HTTP-TCP-In"; DisplayName="HTTP (TCP-In) from Host"; Protocol="TCP"; Port=80},
    @{Name="HTTPS-TCP-In"; DisplayName="HTTPS (TCP-In) from Host"; Protocol="TCP"; Port=443}
)

foreach ($rule in $rules) {
    Write-Host "Creating rule: $($rule.DisplayName)..." -ForegroundColor White

    # Remove existing rule if it exists
    Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue | Out-Null

    # Create new rule allowing from 192.168.96.0/24 network
    New-NetFirewallRule `
        -Name $rule.Name `
        -DisplayName $rule.DisplayName `
        -Direction Inbound `
        -Protocol $rule.Protocol `
        -LocalPort $rule.Port `
        -RemoteAddress 192.168.96.0/24 `
        -Action Allow `
        -Enabled True `
        -ErrorAction SilentlyContinue | Out-Null

    if ($?) {
        Write-Host "  Created" -ForegroundColor Green
    } else {
        Write-Host "  Skipped (may not be relevant for this VM)" -ForegroundColor Gray
    }
}

# Enable ICMP (ping) from host network
Write-Host ""
Write-Host "Enabling ICMP (ping) from host..." -ForegroundColor White
Remove-NetFirewallRule -Name "ICMP-In-Host" -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule `
    -Name "ICMP-In-Host" `
    -DisplayName "ICMP Echo Request (Ping) from Host" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -RemoteAddress 192.168.96.0/24 `
    -Action Allow `
    -Enabled True `
    -ErrorAction SilentlyContinue | Out-Null

if ($?) {
    Write-Host "  Enabled" -ForegroundColor Green
} else {
    Write-Host "  Failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FIREWALL RULES CREATED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Host machine (192.168.96.0/24 network) can now connect to this VM" -ForegroundColor Green
Write-Host ""
