<#
  .SYNOPSIS
  Create a New Technician user for Clients.

  .DESCRIPTION
  New-TechUser.ps1 will create a new asg user for a domain controller and assign the available Duo and VPN groups if they exist.
  
  .PARAMETER FirstName
  Specifies the First Name of the user to create.

  .PARAMETER LastName
  Specifies the Last Name of the user to create.

  .PARAMETER Password
  This must be passed in as a secure string for Security purposes.

  .INPUTS
  FirstName - String
  LastName - String
  Password - SecureString  

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\New-TechUser.log  

  .EXAMPLE
  PS> .\New-TechUser.ps1 -FirstName 'Chris' -LastName 'Calverley' -Password [SecureString]
  Creates a new user with the display name Chris Calverley, returns the sam account name to the console, Writes all information to the log.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 19, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  # The First Name of the user you are creating
  [Parameter(mandatory=$true)]
  [String]
  $FirstName,
  # The Last Name of the user you are creating
  [Parameter(mandatory=$true)]
  [String]
  $LastName,
  # The Password to be assigned to the account
  [Parameter(mandatory=$true)]
  [SecureString]
  $Password
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Function Find-User {
  param(
    [Parameter(Mandatory=$true)][string]$SamAccountName
  )
  try {
    Get-ADUser -identity $Sam -erroraction Stop | Out-Null
    Return 'Exists'
  } catch {
    Return $SamAccountName
  }

}

$Domain = $env:USERDNSDOMAIN
$displayName = "$FirstName $LastName"
Write-log -message "Creating user $displayname on the following Domain: $domain"
$Sam = "$($firstname[0])"+"$lastName"+"-ASG"
Write-log -message "Users login name will be $sam"

$OU = (((get-aduser -filter * | Where-object -Property SamaccountName -like '*-ASG' | Select-Object -First 1).DistinguishedName)-split "," | Select-Object -Skip 1)-join','
Write-log -message "User will be added to the following ou: $findlocation"

$ApplySAM = Find-User -SamAccountName $Sam

if ($ApplySAM -eq 'Exists') {
  Write-log -message "UserName $sam exists in the current structure, verifying persons"
  if ($(Get-ADUser -identity $Sam).GivenName -match "$firstName" -and $(Get-ADUser -identity $Sam).Surname -Match "$LastName") {
    Write-Log -message "$sam User confirmed to already exist in this context"
    $UserExists = $true
  } else {
    Write-log -message "A user with the username $sam exists, however the first and last names do not match, this is a new user"
    $sam = "$($firstname[0])$($FirstName[1])"+"$lastName"+"-ASG"
    Write-log -message "Checking the following UserName : $Sam"
    $ApplySAM = Find-User -SamAccountName $Sam
    if ($ApplySAM -eq 'Exists') {
      if ($(Get-ADUser -identity $Sam).GivenName -match "$firstName" -and $(Get-ADUser -identity $Sam).Surname -Match "$LastName") {
        Write-Log -message "$sam User confirmed to already exist in this context"
        $UserExists = $true
      } else {
        Write-log -message "Can not create a unique Sam Account Name for $FirstName $LastName Multiple instances exist" -type ERROR
        Throw "Can not create a unique Sam Account Name for $FirstName $LastName Multiple instances exist"
      }
    }
  }
}


if(!$UserExists) {
  Write-Log -message "Creating User $Sam"
  New-ADUSER -Name $Displayname -SamAccountName $SAM -GivenName $Firstname -Surname $Lastname -Description "ASG Support Team" -AccountPassword $Password -Enable $true -Path $OU -PasswordNeverExpires $true
  $SAM | ForEach-Object { 
    # construct the UserPrincipalName
    $upn = "{0}@{1}" -f $_, $Domain
    Write-Log -Message "UPN to be set to: $UPN"
    Get-ADUser $SAM | Set-ADUser -UserPrincipalName $upn -erroraction SilentlyContinue
    }
}

Write-Log -Message "User exists or has been created, obtaining groups"
$groups = $(get-adgroup -filter "Name -like 'Domain Admin*'" | Select-Object -expandproperty Name), $(get-adgroup -filter "Name -like 'Duo*'" | Select-Object -expandproperty Name), $(get-adgroup -filter "Name -like 'VPN*'" | Select-Object -expandproperty Name)
Write-Log -message "The Following Groups have been found: `r $groups"

$groups | foreach-object { Add-ADPrincipalGroupMembership -Identity $SAM -MemberOf $_ } -ErrorAction SilentlyContinue 

Clear-Files
Return "$SAM Account Created Successfully"