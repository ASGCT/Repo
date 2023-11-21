<#
  .SYNOPSIS
  Sets the logon as value for a service

  .DESCRIPTION
  Sets the logon as value for a specified service if desired, 
  Resets all services using that logon credential if no service is specified.
  
  .PARAMETER LogonAs
  The username to use for the logon as 

  .PARAMETER Password
  A Secure string password for the user you are configuring to login as.

  .PARAMETER ServiceNames
  A string array of targetted services to set the desired crentials upon. 

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Set-ServiceLogon.log  
  Event viewer source ASG-Monitoring
  Event IDs 
    7001 = services with specified credentials were not found.
    7002 = the return result of the service credential change was something other than 0
    7010 = Successful change of credentials for the service.

  .EXAMPLE
  PS> .\Set-ServiceLogon.ps1 -LogonAs 'WAD\tech.support' -Password [Secure.String]
  Checks for all services where the logonas name is set to 'WAD\tech.support' and sets the credentials to the new password.

  .EXAMPLE
  PS> .\Set-ServiceLogon.ps1 -LogonAs 'WAD\tech.support' -Password [Secure.String] -ServiceNames 'testservice','testservice1'
  Sets 'testservice' and 'testservice1' logon credentials to the logonas name and password.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 21, 2023
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
  $SNames += get-wmiobject -namespace "root\cimv2" -Class Win32_Service -Filter "StartName = '$($LogonAs.replace('\','\\'))'"
} else {
  Foreach ($Name in $ServiceNames){
  $sNames += get-wmiobject -namespace "root\cimv2" -Class Win32_Service -Filter "Name = '$ServiceNames'"
  }
}
Write-log -message 'WARNING - We are about to change service credentials.' -type log

if (!($snames)) {
  Write-log -message "No services were found using $LogonAs for credential validation" -type Log
  Write-NewEventlog -EventID 7001 -EntryType 'Error' -Message "$LogonAS credentials could not found on any service, please verify you are inputting the proper login name with domain using $($MyInvocation.ScriptName)"
  clear-files
  throw "No services were found using $LogonAs for credential validation"
}

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
  Clear-Files
  Throw "$($MyInvocation.ScriptName) failed to reset the credentials on $failurecount services. `rPlease review the eventlogs for an event id of 7002 for service names. `rService names can also be found in the scripts log file."
} else {
  if (!($ServiceNames)) {
    Clear-Files
    Return "$($MyInvocation.ScriptName) found and successfully reset the credentials for all services using the login name of $LogonAs"
  } else {
    Clear-Files
    Return "$($MyInvocation.ScriptName) found and successfully reset the credentials for $serviceNames"
  }
}


