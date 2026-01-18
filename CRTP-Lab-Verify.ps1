# ========================================
# CRTP Lab Verification Script
# Run on: Any domain controller
# Purpose: Verify forest trust configuration
# ========================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CRTP Lab Trust Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Determine which machine we're on
$computerName = $env:COMPUTERNAME
$domain = (Get-ADDomain).DNSRoot

Write-Host "Running on: $computerName" -ForegroundColor Yellow
Write-Host "Domain: $domain" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check all trusts
Write-Host "[1/5] Checking trust relationships..." -ForegroundColor Cyan
Write-Host ""

$trusts = Get-ADTrust -Filter * -ErrorAction SilentlyContinue

if ($trusts) {
    foreach ($trust in $trusts) {
        Write-Host "  Trust: $($trust.Name)" -ForegroundColor Green
        Write-Host "    Source: $($trust.Source)" -ForegroundColor Gray
        Write-Host "    Target: $($trust.Target)" -ForegroundColor Gray
        Write-Host "    Direction: $($trust.Direction)" -ForegroundColor Gray
        Write-Host "    Type: $($trust.TrustType)" -ForegroundColor Gray
        Write-Host "    Forest Transitive: $($trust.ForestTransitive)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "  [WARN] No trusts found!" -ForegroundColor Yellow
}

# Test 2: nltest verification
Write-Host "[2/5] nltest domain trusts..." -ForegroundColor Cyan
nltest /domain_trusts /all_trusts
Write-Host ""

# Test 3: DNS resolution tests
Write-Host "[3/5] DNS resolution tests..." -ForegroundColor Cyan
Write-Host ""

$testDomains = @(
    @{Name="mcorp-dc.moneycorp.local"; IP="192.168.96.10"},
    @{Name="ecorp-dc.eurocorp.local"; IP="192.168.96.11"},
    @{Name="dcorp-dc.dollarcorp.moneycorp.local"; IP="192.168.96.12"}
)

foreach ($test in $testDomains) {
    Write-Host "  Testing: $($test.Name)" -ForegroundColor Yellow
    $dnsResult = Resolve-DnsName $test.Name -ErrorAction SilentlyContinue
    if ($dnsResult) {
        Write-Host "    [OK] Resolves to: $($dnsResult.IPAddress)" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Cannot resolve" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Network connectivity
Write-Host "[4/5] Network connectivity tests..." -ForegroundColor Cyan
Write-Host ""

$testIPs = @("192.168.96.10", "192.168.96.11", "192.168.96.12")

foreach ($ip in $testIPs) {
    Write-Host "  Pinging: $ip" -ForegroundColor Yellow
    $pingResult = Test-Connection -ComputerName $ip -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "    [OK] Reachable" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Not reachable" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Cross-forest queries
Write-Host "[5/5] Cross-forest query tests..." -ForegroundColor Cyan
Write-Host ""

$domainsToTest = @()

switch ($domain) {
    "moneycorp.local" {
        $domainsToTest = @("eurocorp.local", "dollarcorp.moneycorp.local")
    }
    "dollarcorp.moneycorp.local" {
        $domainsToTest = @("eurocorp.local", "moneycorp.local")
    }
    "eurocorp.local" {
        $domainsToTest = @("moneycorp.local", "dollarcorp.moneycorp.local")
    }
}

foreach ($testDomain in $domainsToTest) {
    Write-Host "  Querying domain: $testDomain" -ForegroundColor Yellow
    try {
        $domainInfo = Get-ADDomain -Server $testDomain -ErrorAction Stop
        Write-Host "    [OK] Successfully queried $testDomain" -ForegroundColor Green
        Write-Host "      NetBIOS: $($domainInfo.NetBIOSName)" -ForegroundColor Gray
        Write-Host "      Forest: $($domainInfo.Forest)" -ForegroundColor Gray
    } catch {
        Write-Host "    [ERROR] Failed to query: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Verification Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Expected CRTP Lab Structure:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  moneycorp.local (Forest Root)" -ForegroundColor White
Write-Host "    └── dollarcorp.moneycorp.local (Child Domain)" -ForegroundColor White
Write-Host ""
Write-Host "  eurocorp.local (Separate Forest)" -ForegroundColor White
Write-Host ""
Write-Host "  Forest Trust: moneycorp.local <-> eurocorp.local (Bidirectional)" -ForegroundColor White
Write-Host ""
Write-Host "  This allows dollarcorp to access eurocorp through transitive trust" -ForegroundColor Gray
Write-Host ""
