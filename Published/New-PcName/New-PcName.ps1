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
  [Parameter(Mandatory=$true, Position=0)][String]$NewName,
  [Parameter(Mandatory=$true, Position=1)][String]$UserName,
  [Parameter(Mandatory=$true, Position=2)][securestring]$Password,
  [Parameter(Mandatory=$false, Postion=3)][Switch]$Restart
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Write-Log -message "Current ComputerName is: $env:ComputerName"
Write-Log -message "New ComputerName should be: $NewName"
Write-Log -message "Attempting to rename computer to: $NewName"
[pscredential]$Credential =  New-Object System.Management.Automation.PSCredential ($userName, $Password)
if (!$restart){
  Write-Log -message 'No restart will be enforced'
  if ($env:ComputerName -eq $env:USERDOMAIN) {
    #Workgroup
    Write-Log -message 'Computer is not part of a domian using local credentials'
    Rename-Computer -NewName $NewName -LocalCredential $Credential -Force
  } else {
    #Domain
    Write-Log -message 'Computer is part of a domian using domain credentials'
    Rename-Computer -NewName $NewName -DomainCredential $Credential -Force
  }
  
} else {
  Write-Log -message 'restart is enforced'
  if ($env:ComputerName -eq $env:USERDOMAIN) {
    #Workgroup
    Write-Log -message 'Computer is not part of a domian using local credentials'
    Rename-Computer -NewName $NewName -LocalCredential $Credential -Restart -Force
  } else {
    #Domain
    Rename-Computer -NewName $NewName -DomainCredential $Credential -Restart -Force
    Write-Log -message 'Computer is part of a domian using domain credentials'
  }
}
