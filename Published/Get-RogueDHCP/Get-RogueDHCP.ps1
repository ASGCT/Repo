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
Param()

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$AllowedDHCPServer = (Get-NetIPConfiguration | where { $_.InterfaceAlias -notmatch 'Loopback'} | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress

$DownloadURL = "https://raw.githubusercontent.com/ASGCT/Repo/main/Published/Get-RogueDHCP/DHCPTest.exe"
$DownloadLocation = ".\DHCPTest"

If (!(Test-Path $DownloadLocation)){
  new-item $DownloadLocation -ItemType Directory -force
}
If (!(Test-Path "$DownloadLocation\DHCPTest.exe")) {
  Invoke-WebRequest -UseBasicParsing -Uri $DownloadURL -OutFile "$($DownloadLocation)\DHCPTest.exe"
}

$Tests = 0
$ListedDHCPServers = do {
    & "$DownloadLocation\DHCPTest.exe" --quiet --query --print-only 54 --wait --timeout 3
    $Tests ++
} while ($Tests -lt 2)

$DHCPHealth = foreach ($ListedServer in $ListedDHCPServers) {
  if ($ListedServer -notin $AllowedDHCPServer) { "Rogue DHCP Server found. IP of rogue server is $ListedServer" }
}

if (!$DHCPHealth) { $DHCPHealth = "Healthy. No Rogue DHCP servers found." }

Return $DHCPHealth -join "`r`n"
