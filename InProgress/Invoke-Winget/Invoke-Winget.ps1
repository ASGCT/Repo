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
  [parameter(Mandatory=$true)][ValidateSet('Install','Upgrade','Uninstall')][string]$Action,
  [parameter(Mandatory=$false)][Validateset('ID','Name')][string]$Type = 'ID',
  [parameter(Mandatory=$true)][string]$Item
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

#ensure that psgallery is trusted.
Set-PSRepository -Name psgallery -InstallationPolicy Trusted

#check for modules
try {winget} 
Catch {Write-log -message 'Winget is not installed, installation may take time' -type Log
  Install-Module WingetTools
  Install-WinGet
  winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --force
}

Switch ($Action) {
  'Install' {
      $arugment = 'Install '
  }
  'Upgrade' {
      $arugment = 'Upgrade '
  }
  'Uninstall' {
      $arugment = 'Uninstall '
  }
  default {
    Write-log -message 'ERROR : An Unhandled exception has occurred' -type ERROR
    throw 'ERROR : An Unhandled exception has occurred'
  }
}

If ($type -eq 'ID') {
  $argument = "$argument--ID "
}

Winget $argument $Item