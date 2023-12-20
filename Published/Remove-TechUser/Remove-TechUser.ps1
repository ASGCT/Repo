<#
  .SYNOPSIS
  Removes one or more asg ad users from Active Directory

  .DESCRIPTION
  Remove-TechUser removes desired -ASG accounts from Active directory
  
  .PARAMETER UserName
  Specifies the UserName or UserNames designated for removal

  .INPUTS
  UserName 

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Remove-TechUser.log  

  .EXAMPLE
  PS> .\Remove-TechUser.ps1 -UserName 'CCalverley-ASG'
  Removes CCalverley-ASG's active directory account.

  .EXAMPLE
  PS> .\Remove-TechUser.ps1 -UserName 'CCalverley-ASG', 'David-ASG'
  Removes CCalverley-ASG and David-ASG active directory accounts.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 20, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [parameter(Mandatory=$true)][String[]]$UserName

)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

foreach ($User in $UserName){
  if ($User -notlike '*-ASG') {
    Write-Log -message "User : $User is not an ASG account Will not remove account."
    Continue
  }
  Write-Log -Message "Finding user : $User"

  if (!(Get-ADUser -Identity $User)){
    Write-Log -Message "Search for $User resulted in no known user" 
    Continue
  }
  Write-Log -message "Successfully Found User: $User"
  Write-Log -message "Removing User: $User"
  Remove-ADUser -Identity $User -Confirm:$false
  Write-Log -message "Verifying Removal of User: $User"
  try {
    Get-ADUser -Identity $User
    Write-log -message "$User is still found in active directory -could not verify removal" -type ERROR
  } catch {
    Write-Log -Message "$User Successfully Removed"
  }
  
}
Clear-Files
Return 'Remove-TechUser has successfully Completed.'