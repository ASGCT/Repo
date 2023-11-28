<#
  .SYNOPSIS
  Installs an N-Able Agent

  .DESCRIPTION
  Installs the N-Able agent using server, token, and clientID
  
  .PARAMETER Server
  The Server hostname for the N-able instance.

  .PARAMETER CustomerID
  The id of the customer in N-able.

  .PARAMETER Token
  The installation Token for the instance in N-able.

  .INPUTS
  Inputs are positioned,
   Server - Position 1
   CustomerID - Position 2
   Token - Position 3

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Install-NableAgent.log  

  .EXAMPLE
  PS> .\Install-NableAgent.ps1 n-able.Mycompany.com 123 12345678-hgjf-uetc-tyis-viu8osn7sioe
  Installs the N-able agent for a N-able company named mycompany, with the customer id of 123 and using the token 12345678-hgjf-uetc-tyis-viu8osn7sioe

  .EXAMPLE
  PS> .\Install-NableAgent.ps1 -Server n-able.Mycompany.com -CustomerID 123 -Token 12345678-hgjf-uetc-tyis-viu8osn7sioe
  Installs the N-able agent for a N-able company named mycompany, with the customer id of 123 and using the token 12345678-hgjf-uetc-tyis-viu8osn7sioe.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 28, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  # Parameter help description
  [Parameter(Mandatory=$true,Position = 0)]
  [ValidatePattern ('N-Able.asgct.com')]
  $Server,
  [Parameter(Mandatory=$true, Position= 1)]
  [Int]
  $CustomerID,
  [Parameter(Mandatory=$true, Position=2)]
  [ValidatePattern('^(([a-z]|\d){8}-([a-z]|\d){4}-([a-z]|\d){4}-([a-z]|\d){4}-([a-z]|\d){12})$')]
  $Token
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock
}

$arguments = "/s /v`" /qn CUSTOMERID=`"$CustomerID`" CUSTOMERSPECIFIC=1 REGISTRATION_TOKEN=`"$Token`" SERVERPROTOCOL=HTTPS SERVERADDRESS=`"$Server`" SERVERPORT=443`""

write-log -message "Inputted server : $Server"
write-log -message "Inputted CustomerID : $CustomerID"
write-log -message "Inputted token : $Token"
write-log -message "Formatted Response Arguments : `r$Arguments"

Invoke-webrequest -UseBasicParsing -Uri "https://N-able.asgct.com/download/current/winnt/N-central/WindowsAgentSetup.exe" -OutFile "C:\\temp\\WindowsAgentSetup.exe"
Start-Process -FilePath "C:\temp\WindowsAgentSetup.exe" -ArgumentList $arguments -Wait
If (!(Get-Package 'Windows Agent')) {
  Write-Log -Message 'Windows Agent did not install properly, Potentially gave the wrong Customer ID, Please Doublecheck' -Error
  Throw 'Windows Agent did not install properly, Potentially gave the wrong Customer ID, Please Doublecheck'
}
Write-Log -Message 'Windows Agent has installed Successfully'
Return 'Windows Agent has installed Successfully'