<#
  .SYNOPSIS
  Give the ability to hide an installation from removal

  .DESCRIPTION
  Apply a registry key to hide an application from removal.
  
  .PARAMETER Name
  The Name of the application you wish to hide as seen in the software list.

  .INPUTS
  Name (the name of the application as seen in the software list)

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Hide-Application.log  

  .EXAMPLE
  PS> .\Hide-Application.ps1 -Name 'Windows Agent'
  Hides the Windows Agent application from the software list in windows preventing it from being removed.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 04, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true, Position = 0)][string]$Name
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$PSPath = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq "$Name" } | Select-Object -ExpandProperty PSPath

If (!($Pspath)) {
  Write-Log -Message "$Name is not a valid installed program, the name can not be found in the uninstall list" -Type ERROR 
  Throw "$Name is not a valid installed program, the name can not be found in the uninstall list"
}

Write-Log -Message "Found $Name at $($PsPath.PSChildName) Applying registry key to hide installation."
New-ItemProperty -Path $PSPath -Name 'SystemComponent' -Value 1 | Out-Null

Write-Log -Message 'Verifying hiding of application'

If ((Get-ItemPropertyValue $PSPath -Name SystemComponent) -ne 1) {
  Write-Log -Message "Hiding $Name Failed Could not set SystemComponent to 1" -Type ERROR
  throw "Hiding $Name Failed Could not set SystemComponent to 1"
}

Write-log "Confirmed $Name does have a system component of 1, Application should be hidden."
return "Application $Name Successfully hidden."