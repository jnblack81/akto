@echo off
REM ========================================
REM CRTP LAB AUTO-CONFIGURATION BATCH
REM Run this ONCE from Windows host
REM ========================================

echo ========================================
echo CRTP LAB AUTO-CONFIGURATION
echo ========================================
echo.

REM Configure mcorp-dc
echo [1/2] Configuring mcorp-dc...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ComputerName mcorp-dc.moneycorp.local -Credential (New-Object System.Management.Automation.PSCredential('moneycorp\Administrator', (ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force))) -ScriptBlock { Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11 -ErrorAction SilentlyContinue; $p = ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force; Remove-ADTrust -Identity 'eurocorp.local' -Confirm:$false -ErrorAction SilentlyContinue; Add-ADTrust -Name 'eurocorp.local' -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $p -Confirm:$false; Write-Host 'MCORP-DC DONE' }"

echo.

REM Configure ecorp-dc
echo [2/2] Configuring ecorp-dc...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ComputerName ecorp-dc.eurocorp.local -Credential (New-Object System.Management.Automation.PSCredential('eurocorp\Administrator', (ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force))) -ScriptBlock { Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10 -ErrorAction SilentlyContinue; $p = ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force; Remove-ADTrust -Identity 'moneycorp.local' -Confirm:$false -ErrorAction SilentlyContinue; Add-ADTrust -Name 'moneycorp.local' -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $p -Confirm:$false; Write-Host 'ECORP-DC DONE' }"

echo.
echo ========================================
echo CONFIGURATION COMPLETE!
echo ========================================
echo.

pause
