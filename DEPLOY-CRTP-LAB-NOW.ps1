# ========================================
# CRTP LAB AUTO-DEPLOYMENT SCRIPT
# RUN THIS ONE SCRIPT - IT DOES EVERYTHING
# ========================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "CRTP LAB AUTO-DEPLOYMENT" -ForegroundColor Red
Write-Host "THIS SCRIPT DOES EVERYTHING" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Configuration
$mcorpDC = "mcorp-dc.moneycorp.local"
$ecorpDC = "ecorp-dc.eurocorp.local"
$password = "Psychi@Lab2024!"
$trustPassword = "Psychi@Lab2024!"

# Determine where we are
$currentDomain = (Get-ADDomain).DNSRoot
$currentComputer = $env:COMPUTERNAME

Write-Host "Running on: $currentComputer" -ForegroundColor Yellow
Write-Host "Domain: $currentDomain" -ForegroundColor Yellow
Write-Host ""

# ========================================
# STEP 1: CONFIGURE MCORP-DC
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Configuring mcorp-dc" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($currentDomain -eq "moneycorp.local" -or $currentDomain -eq "dollarcorp.moneycorp.local") {
    Write-Host "Configuring moneycorp.local forest trust..." -ForegroundColor Yellow
    Write-Host ""

    # DNS Forwarder
    Write-Host "[1/5] Setting up DNS forwarder for eurocorp.local..." -ForegroundColor Yellow
    try {
        $forwarder = Get-DnsServerZone -Name "eurocorp.local" -ErrorAction SilentlyContinue -Server $mcorpDC
        if (-not $forwarder) {
            Invoke-Command -ComputerName $mcorpDC -ScriptBlock {
                Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11
            }
            Write-Host "  [OK] DNS forwarder created" -ForegroundColor Green
        } else {
            Write-Host "  [OK] DNS forwarder exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] DNS forwarder: $_" -ForegroundColor Yellow
        Write-Host "  Trying direct command..." -ForegroundColor Yellow
        Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11 -ErrorAction SilentlyContinue
    }

    # Test DNS
    Write-Host ""
    Write-Host "[2/5] Testing DNS resolution..." -ForegroundColor Yellow
    $dnsTest = Resolve-DnsName ecorp-dc.eurocorp.local -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Write-Host "  [OK] ecorp-dc.eurocorp.local -> $($dnsTest.IPAddress)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Cannot resolve ecorp-dc.eurocorp.local" -ForegroundColor Red
    }

    # Test network
    Write-Host ""
    Write-Host "[3/5] Testing network connectivity..." -ForegroundColor Yellow
    $ping = Test-Connection -ComputerName 192.168.96.11 -Count 2 -Quiet
    if ($ping) {
        Write-Host "  [OK] Can ping ecorp-dc (192.168.96.11)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Cannot ping ecorp-dc" -ForegroundColor Red
    }

    # Remove existing broken trust
    Write-Host ""
    Write-Host "[4/5] Removing any existing broken trust..." -ForegroundColor Yellow
    try {
        $existingTrust = Get-ADTrust -Filter "Target -eq 'eurocorp.local'" -Server moneycorp.local -ErrorAction SilentlyContinue
        if ($existingTrust) {
            Write-Host "  Removing existing trust..." -ForegroundColor Yellow
            Remove-ADTrust -Identity "eurocorp.local" -Server moneycorp.local -Confirm:$false -ErrorAction Stop
            Write-Host "  [OK] Removed" -ForegroundColor Green
            Start-Sleep -Seconds 5
        } else {
            Write-Host "  [OK] No existing trust to remove" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] $_" -ForegroundColor Yellow
    }

    # Create forest trust
    Write-Host ""
    Write-Host "[5/5] Creating forest trust..." -ForegroundColor Yellow
    try {
        $securePass = ConvertTo-SecureString $trustPassword -AsPlainText -Force

        Add-ADTrust `
            -Name "eurocorp.local" `
            -TrustType Forest `
            -TrustDirection Bidirectional `
            -ForestTransitive $true `
            -TrustPassword $securePass `
            -Server moneycorp.local `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "  [OK] Forest trust created!" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] PowerShell method failed: $_" -ForegroundColor Red
        Write-Host "  Trying netdom..." -ForegroundColor Yellow

        $netdomCmd = "netdom trust moneycorp.local /domain:eurocorp.local /add /twoway /realm /passwordt:$trustPassword /usero:eurocorp\Administrator /passwordo:$password"
        Invoke-Expression $netdomCmd

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Trust created with netdom" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] netdom failed too" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds 5

    Write-Host ""
    Write-Host "[MCORP-DC] Configuration complete!" -ForegroundColor Green
    Write-Host ""

} else {
    Write-Host "[SKIP] Not on moneycorp domain - will configure remotely" -ForegroundColor Yellow
}

# ========================================
# STEP 2: CONFIGURE ECORP-DC
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Configuring ecorp-dc" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($currentDomain -eq "eurocorp.local") {
    Write-Host "Configuring eurocorp.local forest trust..." -ForegroundColor Yellow
    Write-Host ""

    # DNS Forwarder
    Write-Host "[1/5] Setting up DNS forwarder for moneycorp.local..." -ForegroundColor Yellow
    try {
        $forwarder = Get-DnsServerZone -Name "moneycorp.local" -ErrorAction SilentlyContinue
        if (-not $forwarder) {
            Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10
            Write-Host "  [OK] DNS forwarder created" -ForegroundColor Green
        } else {
            Write-Host "  [OK] DNS forwarder exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] $_" -ForegroundColor Yellow
    }

    # Test DNS
    Write-Host ""
    Write-Host "[2/5] Testing DNS resolution..." -ForegroundColor Yellow
    $dnsTest = Resolve-DnsName mcorp-dc.moneycorp.local -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Write-Host "  [OK] mcorp-dc.moneycorp.local -> $($dnsTest.IPAddress)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Cannot resolve mcorp-dc.moneycorp.local" -ForegroundColor Red
    }

    # Test network
    Write-Host ""
    Write-Host "[3/5] Testing network connectivity..." -ForegroundColor Yellow
    $ping = Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet
    if ($ping) {
        Write-Host "  [OK] Can ping mcorp-dc (192.168.96.10)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Cannot ping mcorp-dc" -ForegroundColor Red
    }

    # Remove existing broken trust
    Write-Host ""
    Write-Host "[4/5] Removing any existing broken trust..." -ForegroundColor Yellow
    try {
        $existingTrust = Get-ADTrust -Filter "Target -eq 'moneycorp.local'" -ErrorAction SilentlyContinue
        if ($existingTrust) {
            Write-Host "  Removing existing trust..." -ForegroundColor Yellow
            Remove-ADTrust -Identity "moneycorp.local" -Confirm:$false -ErrorAction Stop
            Write-Host "  [OK] Removed" -ForegroundColor Green
            Start-Sleep -Seconds 5
        } else {
            Write-Host "  [OK] No existing trust to remove" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] $_" -ForegroundColor Yellow
    }

    # Create forest trust
    Write-Host ""
    Write-Host "[5/5] Creating forest trust..." -ForegroundColor Yellow
    try {
        $securePass = ConvertTo-SecureString $trustPassword -AsPlainText -Force

        Add-ADTrust `
            -Name "moneycorp.local" `
            -TrustType Forest `
            -TrustDirection Bidirectional `
            -ForestTransitive $true `
            -TrustPassword $securePass `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "  [OK] Forest trust created!" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] PowerShell method failed: $_" -ForegroundColor Red
        Write-Host "  Trying netdom..." -ForegroundColor Yellow

        $netdomCmd = "netdom trust eurocorp.local /domain:moneycorp.local /add /twoway /realm /passwordt:$trustPassword /usero:moneycorp\Administrator /passwordo:$password"
        Invoke-Expression $netdomCmd

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Trust created with netdom" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] netdom failed too" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds 5

    Write-Host ""
    Write-Host "[ECORP-DC] Configuration complete!" -ForegroundColor Green
    Write-Host ""

} else {
    Write-Host "[INFO] Not on eurocorp domain" -ForegroundColor Yellow
    Write-Host "You need to run this script on ecorp-dc also" -ForegroundColor Yellow
}

# ========================================
# STEP 3: VERIFY EVERYTHING
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking all trusts..." -ForegroundColor Yellow
Write-Host ""

$allTrusts = Get-ADTrust -Filter * -ErrorAction SilentlyContinue

if ($allTrusts) {
    foreach ($trust in $allTrusts) {
        Write-Host "Trust: $($trust.Name)" -ForegroundColor Green
        Write-Host "  Direction: $($trust.Direction)" -ForegroundColor Gray
        Write-Host "  Type: $($trust.TrustType)" -ForegroundColor Gray
        Write-Host "  Transitive: $($trust.ForestTransitive)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "[WARN] No trusts found!" -ForegroundColor Yellow
}

Write-Host "nltest output:" -ForegroundColor Cyan
nltest /domain_trusts /all_trusts

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "WHAT TO DO NEXT:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. If you ran this on dcorp-dc or mcorp-dc:" -ForegroundColor White
Write-Host "   Copy this script to ecorp-dc and run it there too" -ForegroundColor White
Write-Host ""
Write-Host "2. If you ran this on ecorp-dc:" -ForegroundColor White
Write-Host "   Copy this script to mcorp-dc and run it there too" -ForegroundColor White
Write-Host ""
Write-Host "3. After running on BOTH sides:" -ForegroundColor White
Write-Host "   Forest trust should be working!" -ForegroundColor White
Write-Host ""
Write-Host "Test with:" -ForegroundColor Cyan
Write-Host "  Get-ADDomain -Server eurocorp.local" -ForegroundColor Gray
Write-Host "  Get-ADDomain -Server moneycorp.local" -ForegroundColor Gray
Write-Host ""
