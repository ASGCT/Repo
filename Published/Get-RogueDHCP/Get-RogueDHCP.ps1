<#
  .SYNOPSIS
  Determine any Rogue DHCP Servers in the environment

  .DESCRIPTION
  Get-RogueDHCP.ps1 returns Healthy or all found Rogue DHCP Servers as an errored State.
  
  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Get-RogueDHCP.log  

  .EXAMPLE
  PS> .\Get-RogueDHCP.ps1 
  Searches and returns any Rogue DHCP Servers found

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 26, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)][String[]]$Exclude
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$AllowedDHCPServer = (Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -notmatch 'Loopback'} | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress

$AllowedDHCPServer += $Exclude
Write-Log -message "Excluded Ip Addresses: `r $AllowedDHCPServer"

$DownloadURL = "https://raw.githubusercontent.com/ASGCT/Repo/main/Published/Get-RogueDHCP/DHCPTest.exe"
$DownloadLocation = ".\DHCPTest"

If (!(Test-Path $DownloadLocation)){
  Write-Log -Message 'Creating folder'
  new-item $DownloadLocation -ItemType Directory -force
}

If (!(Test-Path "$DownloadLocation\DHCPTest.exe")) {
  Write-Log -Message 'Downloading file'
  Invoke-WebRequest -UseBasicParsing -Uri $DownloadURL -OutFile "$($DownloadLocation)\DHCPTest.exe"
}

$Tests = 0
$ListedDHCPServers = do {
    Write-Log -Message "Starting test $Tests"
    & "$DownloadLocation\DHCPTest.exe" --quiet --query --print-only 54 --wait --timeout 3
    $Tests ++
} while ($Tests -lt 2)

Write-Log -Message "Found Listed Servers `r $ListedDHCPServers"

$DHCPHealth = foreach ($ListedServer in $ListedDHCPServers) {
  if ($ListedServer -notin $AllowedDHCPServer) { "Rogue DHCP Server found. IP of rogue server is $ListedServer" }
}
Clear-Files
if (!$DHCPHealth) { 
  Write-Log -Message 'Healthy. No Rogue DHCP servers found.'
  Return "Healthy. No Rogue DHCP servers found." 
} else {
  Write-Log -Message "$($DHCPHealth -join '`r`n')"
  Throw "$($DHCPHealth -join '`r`n')"
}
