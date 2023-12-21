<#
  .SYNOPSIS
  Set a users password, reset the account lockout state, optionally set the password to never expire, and optionally sync to o365

  .DESCRIPTION
  Set-UserPassword.ps1 will determine a user's existance, then set that user's password to the requested password, it will optionally set that password
  to never expire, optionally unlock a locked account, and optionally sync to Office365
  
  .PARAMETER UserName
  The Name of the target user

  .PARAMETER Password
  The password to set on that target user

  .PARAMETER NeverExpire
  Toggles the password to never expire
  
  .PARAMETER Unlock
  Unlocks the user's account if locked
  
  .PARAMETER Sync
  Is a final step of this script and syncs ad objects with a delta sync to Office 365. 

  .INPUTS
  Necessary parameters
    UserName
    Password   

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Set-UserPassword.log  

  .EXAMPLE
  PS> .\Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] 
  Simply sets ccalverley-asg's account password to the password provided.

  .EXAMPLE
  PS> .\Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock
  Sets ccalverley-asg's account password to the provided password and unlocks the account.

  .EXAMPLE
  PS> .\Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock -NeverExpire
  Sets ccalverley-asg's account password to the provided password, unlocks the account, and sets the password to never expire.

  .EXAMPLE
  PS> .\Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock -NeverExpire -Sync
  Sets ccalverley-asg's account password to the provided password, unlocks the account, sets the password to never expire, finally Syncing ad with Office 365.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 21, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true,Position=0)][String]$UserName,
  [Parameter(Mandatory=$true,Position=1)][securestring]$Password,
  [Parameter(Mandatory=$false,Position=2)][Switch]$Unlock,
  [Parameter(Mandatory=$false,Position=3)][Switch]$NeverExpire,
  [Parameter(Mandatory=$false,Position=4)][Switch]$Sync
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Write-Log -message "Verifying User Exists: $UserName"
If (!(Get-ADUser -identity $UserName)) {
  Write-Log -message "No user found with Identity: $UserName" -type ERROR
  Throw "No user found with Identity: $UserName"
}
Write-Log -Message "User Identity: $UserName Confirmed"

Write-Log -Message "Attempting Password reset for: $UserName"
try {
  Set-ADAccountPassword $UserName -NewPassword  $Password -Reset -erroraction Stop
} catch {
  if ($Error[0] -match 'The password does not meet the length, complexity, or history requirement of the domain') {
    Write-Log -message 'The password does not meet domain password complexity' -Type ERROR
    Throw 'The password does not meet domain password complexity'
  } else {
    throw $Error[0]
  }
 }

 Write-Log -Message "$UserName's Password has been reset successfully"

 if($NeverExpire) {
  Write-Log -Message "Setting $UserName's Password to NeverExpire"
  try {
    Set-ADuser -Identity $UserName -PasswordNeverExpires $true
  } catch {
    Write-Log -Message "$($($error[0])| Out-String)" -Type ERROR
    Throw $Error[0]
  }
 }
Write-Log -Message "$UserName's Password has been set to NeverExpire"

If ($Unlock) {
  Write-Log -Message "Attempting Unlock of $UserName's Account"
  try { Unlock-ADAccount -Identity $UserName
  } Catch {
    Write-Log -Message "$($($error[0])| Out-String)" -Type ERROR
    Throw $Error[0]
  }
}

If ($Sync){
  Import-Module ADSync
  Try {
    Write-Log -Message 'Attempting to start an AD Sync Cycle'
    $result = Start-ADSyncSyncCycle -PolicyType Delta
  } Catch {
    Write-Log -Message "$($($error[0])| Out-String)" -Type ERROR
    Throw $Error[0]
  }
  If ($result.result -ne 'Success') {
    Write-Log -message "Sync did not complete successfully: Results `r$($result.result)" -Type ERROR
    Throw "$($result.result)"
  }
  Write-Log -message "Sync has completed Successfully"
}

Return "Set-UserPassword has completed successfully for user: $UserName"