<#
  .SYNOPSIS
  Uninstalls All ConnectWise Control instances

  .DESCRIPTION
  The Uninstall-ScreenConnect.ps1 script removes ConnectWise Control instances from target machine.
  
  .PARAMETER organizationKey
  Specifies the organization key assigned by skykick when you activate a migration job.

  .INPUTS
  InstanceID (Which can be found in the software list contained in the ()'s for the instance)  

  .OUTPUTS
  System.String
  C:\Temp\Uninstall-Screenconnect.log  

  .EXAMPLE
  PS> .\Uninstall-Screenconnect.ps1 
  Removes all installed instances of Screenconnect Client from target machine.

  .EXAMPLE
  PS> .\Uninstall-Screenconnect.ps1 -InstanceID g4539gjdsfoir
  Only removes ScreenConnect Client (g4539gjdsfoir) from the target machine.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  September 07, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Position = 0, Parametersetname = 'AllSVCS', Mandatory = $true)][string]$LogonAs,
  [Parameter(Position = 1, Parametersetname = 'AllSVCS', Mandatory = $true)][securestring]$Password,
  [Parameter(Position = 2, Parametersetname = 'AllSVCS', Mandatory = $false)][string[]]$ServiceNames
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}
$snames = @()

If(!($ServiceNames)){
  $SNames += Get-CimInstance -ClassName Win32_Service -Filter "StartName = '$LogonAs'"| Select-Object -Property *
} else {
  Foreach ($Name in $ServiceNames){
  $sNames += Get-CimInstance -ClassName Win32_Service -Filter "Name = '$ServiceNames'"| Select-Object -Property *
  }
}
Write-log -message 'WARNING - We are about to change service credentials.' -type log

foreach ($service in $SNames) {
  Write-log -message "Modifying $($service.name)'s credentials"
  $service.Change($null,$null,$null,$null,$null,$null,$LogonAs,$Password)
}


