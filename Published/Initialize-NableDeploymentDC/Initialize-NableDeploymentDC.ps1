<#
  .SYNOPSIS
  Set up a group policy that will install the N-able agent on any new computer or any computer that is missing the n-able agent

  .DESCRIPTION
  Sets up a domain controller to push out the n-able agent for this client.
  ** Does not apply the group policy to any OU **
  
  .PARAMETER CustomerID
  The Customer ID specified in N-able for this client

  .PARAMETER Token
  The never expiring token retrieved from N-able

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Initialize-NableDeploymentDC.log  

  .EXAMPLE
  PS> .\Initialize-NableDeploymentDC.ps1 -CustomerID 261 -Token j43863j3-jfy9-jfu0-ls07-jdi8nch6yfdjo
  Sets up the Domain controller with a group policy named NableAgentDeployment that can be assigned to any ou.

  .EXAMPLE
  PS> .\Initialize-NableDeploymentDC.ps1 261 j43863j3-jfy9-jfu0-ls07-jdi8nch6yfdjo
  Same as above

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 29, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
    # Parameter help description
    [Parameter(Mandatory=$true, Position= 1)]
    [Int]
    $CustomerID,
    [Parameter(Mandatory=$true, Position=2)]
    [ValidatePattern('^(([a-z]|\d){8}-([a-z]|\d){4}-([a-z]|\d){4}-([a-z]|\d){4}-([a-z]|\d){12})$')]
    $Token
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock
}

Write-log -Message "Setting up $env:ComputerName for N-able agent deployment"

$Code = @"
  if(Get-Package 'Windows Agent') {return 'installed'}
  `$FileName = 'Install-NableAgent'
  `$arguments = "-Server N-able.asgct.com -CustomerID $CustomerID -Token $Token"
  Set-ExecutionPolicy Bypass -scope Process -Force
  Set-Location C:\Temp
  `$DownloadLocation = ".\`$FileName"
  `$BaseRepoUrl = "https://raw.githubusercontent.com/ASGCT/Repo/main/Published/`$FileName/"

  `$FullUrl = "`$BaseRepoUrl`$FileName.ps1"

  If (!(Test-Path `$DownloadLocation)) {
      New-Item -ItemType Directory -Name `$DownloadLocation
  }

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -UseBasicParsing -Uri `$FullUrl -OutFile "C:\Temp\`$FileName\`$FileName.ps1"

  If([string]::IsNullOrEmpty(`$arguments)) {
      powershell "& ""C:\Temp\`$FileName\`$FileName.ps1 """
  } else {
      powershell "& ""C:\Temp\`$FileName\`$FileName.ps1 `$arguments"""
  }
"@

#Find the NetLogon folder script if not exists create it, if it does exist replace it.
If(!(Test-Path "$(get-smbshare | Where-Object Name -like 'NetLogon' | Select-Object -expandproperty Path)\DeployNableAgent.ps1")) {
  $NetLogonSharefileName = "$(get-smbshare | Where-Object Name -like 'NetLogon' | Select-Object -expandproperty Path)\DeployNableAgent.ps1"
  New-Item $NetLogonSharefileName -ItemType File
  add-content -path "$(get-smbshare | Where-Object Name -like 'NetLogon' | Select-Object -expandproperty Path)\DeployNableAgent.ps1" -Value $code
}else {
  Set-content -Path "$(get-smbshare | Where-Object Name -like 'NetLogon' | Select-Object -expandproperty Path)\DeployNableAgent.ps1" -Value $code
}

#Generate Orca transform
$GPOName = 'NableAgentDeployment'

#Create the gpo
New-GPO -Name $GPOName | Set-GPPermissions -PermissionLevel gpoedit -TargetName "$(get-adgroup -filter 'Name -like "Administrators"' | Select-Object -ExpandProperty Name)" -TargetType Group
#Scope to only domain computers
Set-GPPermission -Name $GPOName -PermissionLevel GpoApply -TargetName 'Domain Computers' -TargetType Group -Replace
$GPOID = Get-Gpo -all | Where-object DisplayName -match "$GPOName" | Select-object -expandProperty ID | Select-object -expandProperty GUID 
Write-Host "GPO exists as ID $GpoID"
#Remove authenticated users
dsacls "CN={$GPOID},CN=Policies,$((Get-ADDomain).SystemsContainer)" /R "Authenticated Users"
#Give authenticated users read access
Set-GPPermission -Name $GPOName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead
#add policies
Set-GPRegistryValue -Name $GPOName -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName EnableLogonScriptDelay -Type DWord -Value 1
Set-GPRegistryValue -Name $GPOName -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName AsyncScriptDelay -Type DWord -Value 5
#Turn it on 
Get-GPO -Guid $GPOID
Start-Sleep -Seconds 5

#add startup script
$root = $(get-addomain).forest
$DC = $(get-addomaincontroller).Name
$powershell = "\\$DC\netlogon\DeployNableAgent.ps1"
$GpRoot = "C:\Windows\SYSVOL\sysvol\$root\Policies\{$GPOID}"
$machineScriptsPath = "$GPRoot\Machine\Scripts"
if (!(Test-Path "$machineScriptsPath\psscripts.ini")) {
  New-Item "$machineScriptsPath\psscripts.ini" -ItemType File -Force
  New-Item "$machineScriptsPath\scripts.ini" -ItemType File -Force
  New-Item "$machineScriptsPath\Shutdown" -ItemType Directory -force
  New-Item "$machineScriptsPath\Startup" -ItemType Directory -force

  Copy-Item -Path "$(get-smbshare | Where-Object Name -like 'NetLogon' | Select-Object -expandproperty Path)\DeployNableAgent.ps1" -Destination "$machineScriptsPath\Startup\DeployNableAgent.ps1" -Force
}
$contents = @("`n[Startup]")
$contents += "0CmdLine=$Powershell"
$contents += "0Parameters="
Set-Content "$machineScriptsPath\psscripts.ini" -Value ($Contents) -Encoding Unicode -Force


$GpIni = Join-Path $GpRoot "gpt.ini"
$MachineGpExtensions = '{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}'
$newVersion = 1
$versionMatchInfo = $contents | Select-String -Pattern 'Version=(.+)'
if ($versionMatchInfo.Matches.Groups -and $versionMatchInfo.Matches.Groups[1].Success) {
    $newVersion += [int]::Parse($versionMatchInfo.Matches.Groups[1].Value)
}
 
(
    "[General]",
    "gPCMachineExtensionNames=[$MachineGpExtensions]",
    "Version=$newVersion",
    "gPCUserExtensionNames=[$UserGpExtensions]"
) | Out-File -FilePath $GpIni -Encoding ascii
Get-GPO -Guid $GPOID
Clear-Files
Write-NewEventlog -eventid 7010 -message "Initialize-NableDeploymentDC.ps1 Completed Successfully"
return