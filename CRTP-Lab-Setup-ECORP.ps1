# ========================================
# CRTP Lab Configuration - ECORP-DC
# Run on: ecorp-dc (eurocorp.local)
# Domain: eurocorp.local (Separate Forest)
# ========================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP Lab Setup - Forest Trust (ECORP)" -ForegroundColor Cyan
Write-Host "Machine: ecorp-dc (eurocorp.local)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$trustPassword = "Psychi@Lab2024!"
$moneyCorpAdmin = "moneycorp\Administrator"
$moneyCorpDC = "mcorp-dc.moneycorp.local"
$moneyCorpDomain = "moneycorp.local"

# Step 1: Verify DNS Configuration
Write-Host "[1/6] Verifying DNS configuration..." -ForegroundColor Yellow

# Check if conditional forwarder exists
$forwarder = Get-DnsServerZone -Name $moneyCorpDomain -ErrorAction SilentlyContinue

if (-not $forwarder) {
    Write-Host "  Creating DNS conditional forwarder for moneycorp.local..." -ForegroundColor Yellow
    try {
        Add-DnsServerConditionalForwarderZone -Name $moneyCorpDomain -MasterServers 192.168.96.10 -ErrorAction Stop
        Write-Host "  [OK] DNS forwarder created" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to create DNS forwarder: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [OK] DNS forwarder already exists" -ForegroundColor Green
}

# Step 2: Test DNS Resolution
Write-Host ""
Write-Host "[2/6] Testing DNS resolution..." -ForegroundColor Yellow

$dnsTest = Resolve-DnsName $moneyCorpDC -ErrorAction SilentlyContinue
if ($dnsTest) {
    Write-Host "  [OK] Can resolve $moneyCorpDC -> $($dnsTest.IPAddress)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Cannot resolve $moneyCorpDC" -ForegroundColor Red
}

# Step 3: Test Network Connectivity
Write-Host ""
Write-Host "[3/6] Testing network connectivity..." -ForegroundColor Yellow

$pingTest = Test-Connection -ComputerName 192.168.96.10 -Count 2 -Quiet
if ($pingTest) {
    Write-Host "  [OK] Network connectivity to mcorp-dc (192.168.96.10)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Cannot ping 192.168.96.10" -ForegroundColor Red
}

# Step 4: Check Existing Trust
Write-Host ""
Write-Host "[4/6] Checking for existing trust..." -ForegroundColor Yellow

$existingTrust = Get-ADTrust -Filter "Target -eq '$moneyCorpDomain'" -ErrorAction SilentlyContinue

if ($existingTrust) {
    Write-Host "  [WARN] Trust already exists!" -ForegroundColor Yellow
    Write-Host "  Name: $($existingTrust.Name)" -ForegroundColor Gray
    Write-Host "  Direction: $($existingTrust.Direction)" -ForegroundColor Gray
    Write-Host "  Type: $($existingTrust.TrustType)" -ForegroundColor Gray

    Write-Host ""
    Write-Host "  Removing existing broken trust..." -ForegroundColor Yellow
    try {
        Remove-ADTrust -Identity $moneyCorpDomain -Confirm:$false -ErrorAction Stop
        Write-Host "  [OK] Existing trust removed" -ForegroundColor Green
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "  [ERROR] Failed to remove trust: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [OK] No existing trust found" -ForegroundColor Green
}

# Step 5: Create Forest Trust
Write-Host ""
Write-Host "[5/6] Creating bidirectional forest trust..." -ForegroundColor Yellow
Write-Host "  Trust: eurocorp.local <-> moneycorp.local" -ForegroundColor Cyan

try {
    $securePassword = ConvertTo-SecureString $trustPassword -AsPlainText -Force

    Add-ADTrust `
        -Name $moneyCorpDomain `
        -TrustType Forest `
        -TrustDirection Bidirectional `
        -ForestTransitive $true `
        -TrustPassword $securePassword `
        -Confirm:$false `
        -ErrorAction Stop

    Write-Host "  [OK] Forest trust created successfully!" -ForegroundColor Green

} catch {
    Write-Host "  [ERROR] Failed to create trust: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Trying alternative method with netdom..." -ForegroundColor Yellow

    # Try netdom as fallback
    $netdomResult = netdom trust eurocorp.local /domain:$moneyCorpDomain /add /twoway /realm /passwordt:$trustPassword /usero:$moneyCorpAdmin /passwordo:$trustPassword 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Trust created with netdom" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] netdom also failed: $netdomResult" -ForegroundColor Red
    }
}

# Wait for replication
Start-Sleep -Seconds 10

# Step 6: Verify Trust
Write-Host ""
Write-Host "[6/6] Verifying forest trust..." -ForegroundColor Yellow

# Check with Get-ADTrust
$verifyTrust = Get-ADTrust -Filter "Target -eq '$moneyCorpDomain'" -ErrorAction SilentlyContinue

if ($verifyTrust) {
    Write-Host "  [OK] Trust object exists" -ForegroundColor Green
    Write-Host "    Name: $($verifyTrust.Name)" -ForegroundColor Gray
    Write-Host "    Direction: $($verifyTrust.Direction)" -ForegroundColor Gray
    Write-Host "    Type: $($verifyTrust.TrustType)" -ForegroundColor Gray
    Write-Host "    Forest Transitive: $($verifyTrust.ForestTransitive)" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] Trust verification failed" -ForegroundColor Red
}

# Verify with nltest
Write-Host ""
Write-Host "  Trust relationships (nltest):" -ForegroundColor Cyan
nltest /domain_trusts /all_trusts

# Final verification
Write-Host ""
Write-Host "  Attempting trust verification..." -ForegroundColor Cyan
$verifyResult = netdom trust eurocorp.local /domain:$moneyCorpDomain /verify /usero:$moneyCorpAdmin /passwordo:$trustPassword 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Trust verification successful!" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Trust verification: $verifyResult" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ECORP-DC Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run CRTP-Lab-Verify.ps1 on any DC to verify" -ForegroundColor Cyan
Write-Host ""
