<#
  .SYNOPSIS
  Sets the last logged in user on a computer

  .DESCRIPTION
  Will set the last logged in user on a target machine
  
  .PARAMETER User
  The Username of the user to set ie. ccalverley

  .PARAMETER Domain
  Toggles the difference between a local and domain account

  .OUTPUTS
  System.String
  C:\Temp\Set-LastLoggedinUser.log  

  .EXAMPLE
  PS> .\Set-LastLoggedinUser.ps1 -User ccalverley
  Sets the local account ccalverley as the last logged in user

  .EXAMPLE
  PS> .\Set-LastLoggedinUser.ps1 -User ccalverley -Domain
  Sets the machine domain account for ccalverley to the last logged in user

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 07, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)][string]$User,
  [Parameter(Mandatory=$false)][Switch]$domain
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Function Get-Sid {
  param (
    [Parameter(Mandatory = $true)][string]$UserName
  )
  $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

  $items = Get-ChildItem -Path $registryPath

  foreach ($item in $items) {
    $Name = ($item.Name).Replace('HKEY_LOCAL_MACHINE','HKLM:')
    $sid = ($item.Name).Split('\') | Select-Object -Last 1
    $Path = Get-ItemPropertyValue -Path $Name -Name ProfileImagePath
    if ($Path -Like "*$UserName") {
        return $sid
    } 
  }
  return $null
}



$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
$regSAMUser = 'LastLoggedOnSAMUser'
$LLOUSID = 'LastLoggedOnUser'
$SUSID = 'SelectedUserSID'

if (-not (Test-Path $regPath)) {
  Write-Log -message "Registry path not found: $regPath" -type ERROR
   Return "Registry path not found: $regPath"
}
$MYSID = Get-Sid -UserName $User
If (!$MYSID) {
  Write-Log -message "User: $User Does not exist" -type ERROR
  return "User: $User Does not exist"
}
if ($domain) {
  if ($env:computername  -eq $env:userdomain) {
    Write-Log -message "$env:computername is not part of a domain Please rerun without setting -domain" -type ERROR
    return "$env:computername is not part of a domain Please rerun without setting -domain"
    } else { 
    $newLastLoggedInUser = "$env:userdomain\$User"
  }
} else {
  $newLastLoggedInUser = "$env:computername\$User"
}  

Set-ItemProperty -Path $regPath -Name $regSAMUser -Value $newLastLoggedInUser
Set-ItemProperty -Path $regPath -Name $regSAMUser -Value $newLastLoggedInUser
Set-ItemProperty -Path $regPath -Name $LLOUSID -Value $MYSID
Set-ItemProperty -Path $regPath -Name $SUSID -Value $MYSID
 
Write-Log "Last logged-in user set to: $User"


