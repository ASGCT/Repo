<#
  .SYNOPSIS
  Give the ability to Unhide an installation from removal

  .DESCRIPTION
  Apply a registry key to Unhide an application from removal.
  
  .PARAMETER Name
  The Name of the application you wish to reveal to the software list.

  .INPUTS
  Name (the name of the application as seen in the software list)

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Show-Application.log  

  .EXAMPLE
  PS> .\Show-Application.ps1 -Name 'Windows Agent'
  Shows the Windows Agent application in the software list in windows allowing it to being removed.

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

Write-Log -Message "Found $Name at $($PsPath.PSChildName) Applying registry key to show installation."
Set-ItemProperty -Path $PSPath -Name 'SystemComponent' -Value 0 | Out-Null

Write-Log -Message 'Verifying application visibility'

If ((Get-ItemPropertyValue $PSPath -Name SystemComponent) -ne 0) {
  Write-Log -Message "Show $Name Failed Could not set SystemComponent to 0" -Type ERROR
  throw "Show $Name Failed Could not set SystemComponent to 0"
}

Write-log "Confirmed $Name does have a system component of 0, Application should be visible."
return "Application $Name Successfully revealed."