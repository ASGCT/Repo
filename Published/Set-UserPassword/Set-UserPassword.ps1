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