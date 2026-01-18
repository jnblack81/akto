# COPY THIS ENTIRE SCRIPT INTO ECORP-DC POWERSHELL AND PRESS ENTER

Add-DnsServerConditionalForwarderZone -Name 'moneycorp.local' -MasterServers 192.168.96.10 -ErrorAction SilentlyContinue
$p = ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force
Remove-ADTrust -Identity 'moneycorp.local' -Confirm:$false -ErrorAction SilentlyContinue
Add-ADTrust -Name 'moneycorp.local' -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $p -Confirm:$false
Write-Host 'ECORP-DC CONFIGURED!' -ForegroundColor Green
Get-ADTrust -Filter * | Format-Table Name, Direction, TrustType
