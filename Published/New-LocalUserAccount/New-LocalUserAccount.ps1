<#
  .SYNOPSIS
  Adds a local account to a target computer

  .DESCRIPTION
  New-LocalUserAccount adds a local user account, either sets a password or sets the account to no password, Allows for setting of password never expires, Optional descriptions available
  Sets a password to Never expire if desired, and assigns that user to designated groups.
  
  .PARAMETER UserName
  The Name of the user to create

  .PARAMETER Password
  A secure string password

  .PARAMETER PasswordNeverExpires
  Set this switch to set the password to never expire

  .PARAMETER Description
  Fives a description to the user account

  .PARAMETER UserMayNotChangePassword
  Stops the password from being changed

  .PARAMETER Groups
  The Groups you wish to assign the user to.

  .INPUTS
  Above Parameters 

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\New-LocalUserAccount.log  

  .EXAMPLE
  PS> .\New-LocalUserAccount.ps1 -UserName 'Calverley' -Password <SecureString> -PasswordNeverExpires -UserMayNotChangePassword -Groups 'Admin', 'Remote D'

  Adds the user 'Calverley' to the local users group, sets the password to the secure password, sets the password to never expire and never change.
  Then adds 'Calverley' to the Administrators, and the Remote Desktop Users Groups.

  .EXAMPLE
  PS> .\New-LocalUserAccount.ps1 -UserName 'Calverley' -Description 'Generic log in account' -Groups 'Users', 'power U'
  
  Creates a passwordless account 'Calverley' with a description of 'Generic Log in account and adds Calverley to the Users and Power users groups.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 27, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position = 0)][string]$UserName,
  [Parameter(Mandatory=$false, Position = 1)][securestring]$Password,
  [Parameter(Mandatory=$false, Position = 2)][switch]$PasswordNeverExpires,
  [Parameter(Mandatory=$false, Position = 3)][string]$description,
  [Parameter(Mandatory = $false, Position = 4)][Switch]$UserMayNotChangePassword,
  [Parameter(Mandatory = $False, Position = 5)][String[]]$Groups
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$params = @{
  Name = $UserName
  FullName = $UserName
}

If (!$Password) {
  $Params += @{
    NoPassword = $True
  }
} else {
  $Params += @{
    password = $Password
  }
}

If ($PasswordNeverExpires) {
  $Params += @{
    PasswordNeverExpires = $true
  }
}

If (!([String]::IsNullOrEmpty($description))) {
  $Params += @{
    Description = $description
  }
}

if ($UserMayNotChangePassword) {
  $Params += @{
    UserMayNotChangePassword = $True
  }
}
$MultiGroupReturn = $False
$GroupReturns = @()
$User = New-LocalUser @params
Foreach ($group in $groups) {
  if ($(Get-LocalGroup | Where-Object -Property Name -like $group*).count -gt 1) {
    Write-log -message "More than 1 group exists with name $group, You must be more specific"
    $MultiGroupReturn = $True
    $MultiGroupRV += "$(Get-LocalGroup | Where-Object -Property Name -like $group*)"
    Continue
  } else {
    Write-log -message "Adding $($User.Name) to $(Get-LocalGroup | Where-Object -Property Name -like $group*)"
    Add-LocalGroupMember -group $(Get-LocalGroup | Where-Object -Property Name -like $group*) -Member $User
    $GroupReturns += $(Get-LocalGroup | Where-Object -Property Name -like $group*)
  }
}
Write-Log -message "Verification starting"

if (!(Get-LocalUser | Where-Object -Property Name -like $UserName)) {
  Write-Log -message "Verification Failed - Cannot find user $UserName" -Type ERROR
  Throw "Verification Failed - Cannot find user $UserName"
} 

If ($MultiGroupReturn) {
  Write-Log -message "Verification Failed - Duplicate groups exist with the same matching pattern `r $MultigroupRV" -Type ERROR
  throw "Verification Failed - Duplicate groups exist with the same matching pattern `r $MultigroupRV"
} 

Foreach ($gp in $GroupReturns) {
  if(!(Get-LocalGroupMember -Group $gp | Where-Object -Property Name -like "*$username")) {
    Write-Log -Message "Verification Failed - Could not find group member $UserName in Group $Gp" -Type ERROR
    Throw "Verification Failed - Could not find group member $UserName in Group $Gp"
  }
}
Write-Log -message 'All Verification tests Passed'
Return 'All Verification tests Passed'