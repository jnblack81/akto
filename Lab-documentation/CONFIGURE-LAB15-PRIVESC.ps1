# CONFIGURE LAB 15 - LOCAL PRIVILEGE ESCALATION
# Run this as Administrator on dcorp-stdadmin

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURING LAB 15 - LOCAL PRIVILEGE ESCALATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Method 1: Enable AlwaysInstallElevated
Write-Host "[1/3] Configuring AlwaysInstallElevated vulnerability..." -ForegroundColor Yellow

# Create registry keys if they don't exist
$HKCUPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$HKLMPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"

if (-not (Test-Path $HKCUPath)) {
    New-Item -Path $HKCUPath -Force | Out-Null
}
if (-not (Test-Path $HKLMPath)) {
    New-Item -Path $HKLMPath -Force | Out-Null
}

# Set AlwaysInstallElevated to 1
Set-ItemProperty -Path $HKCUPath -Name "AlwaysInstallElevated" -Value 1 -Type DWord
Set-ItemProperty -Path $HKLMPath -Name "AlwaysInstallElevated" -Value 1 -Type DWord

Write-Host "  [DONE] AlwaysInstallElevated enabled (both HKCU and HKLM)" -ForegroundColor Green

# Method 2: Create vulnerable service with unquoted path
Write-Host "[2/3] Creating vulnerable service with unquoted path..." -ForegroundColor Yellow

# Create a directory structure with spaces
$vulnPath = "C:\Program Files\Vulnerable Service"
if (-not (Test-Path $vulnPath)) {
    New-Item -Path $vulnPath -ItemType Directory -Force | Out-Null
}

# Create a dummy executable
$dummyExe = "$vulnPath\VulnService.exe"
Copy-Item "$env:windir\System32\cmd.exe" -Destination $dummyExe -Force

# Create service with unquoted path (intentional vulnerability)
$serviceName = "VulnerableService"
$serviceExists = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($serviceExists) {
    sc.exe delete $serviceName | Out-Null
    Start-Sleep -Seconds 2
}

# Create service with UNQUOTED path (vulnerable)
sc.exe create $serviceName binPath= "C:\Program Files\Vulnerable Service\VulnService.exe" start= auto | Out-Null

# Set weak permissions on the service executable directory
$acl = Get-Acl $vulnPath
$permission = "BUILTIN\Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl -Path $vulnPath -AclObject $acl

Write-Host "  [DONE] Vulnerable service created: $serviceName" -ForegroundColor Green
Write-Host "    Path (unquoted): C:\Program Files\Vulnerable Service\VulnService.exe" -ForegroundColor Gray
Write-Host "    Users have FullControl on: $vulnPath" -ForegroundColor Gray

# Method 3: Create service with modifiable binary
Write-Host "[3/3] Creating service with modifiable binary permissions..." -ForegroundColor Yellow

$vulnService2 = "WeakService"
$vulnPath2 = "C:\Services"
$vulnExe2 = "$vulnPath2\WeakService.exe"

if (-not (Test-Path $vulnPath2)) {
    New-Item -Path $vulnPath2 -ItemType Directory -Force | Out-Null
}

Copy-Item "$env:windir\System32\cmd.exe" -Destination $vulnExe2 -Force

# Create service
$service2Exists = Get-Service -Name $vulnService2 -ErrorAction SilentlyContinue
if ($service2Exists) {
    sc.exe delete $vulnService2 | Out-Null
    Start-Sleep -Seconds 2
}

sc.exe create $vulnService2 binPath= $vulnExe2 start= auto | Out-Null

# Give Users write permission on the executable
$acl2 = Get-Acl $vulnExe2
$permission2 = "BUILTIN\Users", "FullControl", "None", "None", "Allow"
$accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission2
$acl2.SetAccessRule($accessRule2)
Set-Acl -Path $vulnExe2 -AclObject $acl2

Write-Host "  [DONE] Weak service created: $vulnService2" -ForegroundColor Green
Write-Host "    Binary: $vulnExe2" -ForegroundColor Gray
Write-Host "    Users have FullControl on binary" -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LAB 15 CONFIGURATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vulnerabilities configured:" -ForegroundColor Yellow
Write-Host "  1. AlwaysInstallElevated (HKCU + HKLM)" -ForegroundColor White
Write-Host "  2. Unquoted Service Path: VulnerableService" -ForegroundColor White
Write-Host "  3. Modifiable Service Binary: WeakService" -ForegroundColor White
Write-Host ""
Write-Host "Student can now exploit any of these to gain local admin!" -ForegroundColor Green
