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
  [Parameter(Mandatory=$true)][int32]$EventID
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$List = Get-EventLog -LogName Application | Where-Object {$_.EventID -eq "$EventID" -and $_.TimeGenerated -gt (Get-Date).AddHours(-24)} 
$first = $List | Select-Object -Last 1
Write-Log -message "ran $($first.TimeGenerated)"

#Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) Found Log `r$($first.TimeGenerated) `r$($first.Message)"
Write-log "ran $($first.TimeGenerated), Uninstalled $($List.count)"
If ($list.count -gt 1) {
  Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) Found Log `r$($first.TimeGenerated) `r$($first.Message)"
  Return "this machine was affected at $($first.TimeGenerated)"
}