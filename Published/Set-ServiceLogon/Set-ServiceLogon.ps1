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
$failurecount = 0
If(!($ServiceNames)){
  $SNames += get-wmiobject -namespace "root\cimv2" -Class Win32_Service -Filter "StartName = '$LogonAs'"
} else {
  Foreach ($Name in $ServiceNames){
  $sNames += get-wmiobject -namespace "root\cimv2" -Class Win32_Service -Filter "Name = '$ServiceNames'"
  }
}
Write-log -message 'WARNING - We are about to change service credentials.' -type log

foreach ($service in $SNames) {
  Write-log -message "Modifying $($service.name)'s credentials"
  $result = $service.Change($null,$null,$null,$null,$null,$false,$LogonAs,$Password)
  if ($result.ReturnValue -ne 0) {
    write-log -message "$service credentials could not be adjusted, please verify you are inputting the proper login name with domain" -type ERROR
    Write-NewEventlog -EventID 7002 -EntryType 'Error' -Message "$service credentials could not be adjusted, please verify you are inputting the proper login name with domain using $($MyInvocation.ScriptName)"
    $failurecount += 1
  } else {
    Write-log -message "$Service Credentials were changed successfully"
    Write-NewEventlog -EventID 7010 -EntryType 'Information' -Message "$Service Credentials were changed successfully by $($MyInvocation.ScriptName) "
  }
}

if ($failurecount -gt 0) {
  Throw "$($MyInvocation.ScriptName) failed to reset the credentials on $failurecount services. `rPlease review the eventlogs for an event id of 7002 for service names. `rService names can also be found in the scripts log file."
} else {
  if (!($ServiceNames)) {
  Return "$($MyInvocation.ScriptName) found and successfully reset the credentials for all services using the login name of $LogonAs"
  } else {
    Return "$($MyInvocation.ScriptName) found and successfully reset the credentials for $serviceNames"
  }
}


