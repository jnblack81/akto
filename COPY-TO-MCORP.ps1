# COPY THIS ENTIRE SCRIPT INTO MCORP-DC POWERSHELL AND PRESS ENTER

Add-DnsServerConditionalForwarderZone -Name 'eurocorp.local' -MasterServers 192.168.96.11 -ErrorAction SilentlyContinue
$p = ConvertTo-SecureString 'Psychi@Lab2024!' -AsPlainText -Force
Remove-ADTrust -Identity 'eurocorp.local' -Confirm:$false -ErrorAction SilentlyContinue
Add-ADTrust -Name 'eurocorp.local' -TrustType Forest -TrustDirection Bidirectional -ForestTransitive $true -TrustPassword $p -Confirm:$false
Write-Host 'MCORP-DC CONFIGURED!' -ForegroundColor Green
Get-ADTrust -Filter * | Format-Table Name, Direction, TrustType
