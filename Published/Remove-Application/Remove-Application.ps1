<#
  .SYNOPSIS
  Uninstalls an application from a computer

  .DESCRIPTION
  Uninstalls the desired application from a computer
  
  .PARAMETER Name
  The name of the application as it appears in programs and features

  .INPUTS
  Application Name 

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\SciptLogs\Remove-Application.log  

  .EXAMPLE
  PS> .\Remove-Application.ps1 -Name 'DNSFilter Agent
  Uninstalls DNSFilter from a machine

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 10, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [String]$Name
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Function Get-Application {
  $GUID = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq "$Name" } | Select-Object -ExpandProperty UninstallString
  if(!$GUID) {
      Return $Null
  } else {
      return $GUID
  }

}

Write-Log "Attempting to remove $Name"
try {
  Write-log -message "attempting package removal of $Name"
  Get-Package $Name -ErrorAction Stop | Uninstall-Package -force -ErrorAction Stop
} Catch {
  Write-log -message "Could not removal of $Name with get-Package"
}

$Switches = ' /S'

$UID = Get-Application
  If (!($UID)) {
    Write-Log -Message "It does not appear that $Name is installed on $env:COMPUTERNAME."
    Write-NewEventlog -eventid 7011 -message "$($MyInvocation.ScriptName) Could Not Verify $Name is installed"
    Clear-Files
    Return "Success - $Name is not installed."
  }

Write-log -message "attempting package removal of $Name with Ciminstance"
try {(Get-CimInstance -ClassName win32_Product | Where-Object {$_.Name -eq "$Name"} -ErrorAction Stop).Uninstall()}
Catch {Write-Log "Could not find Ciminstance for $Name"}
Start-Sleep -Seconds 20
#verify
$UID = Get-Application 
If (!($UID)) {
  Write-Log -Message "It does not appear that $Name is installed on $env:COMPUTERNAME."
  Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) removed $Name via line 78"
  Clear-Files
  Return "Success - $Name is not installed."
}


$uninstallstring = get-package -name "$Name" -ErrorAction SilentlyContinue | ForEach-Object { $_.metadata['uninstallstring'] }
Write-Log -message "uninstall string $uninstallstring"

$isExeOnly = Test-Path -ErrorAction SilentlyContinue -LiteralPath $uninstallString
if ($isExeOnly) { 
  $uninstallString = "`"$uninstallString`"" 
  $uninstallString += $switches
  cmd.exe /c $uninstallstring
} else {

$UID = Get-Application 
Write-Log -Message "UID uninstall string is $UID"
  If (!($UID)) {
    Write-Log -Message "It does not appear that $Name is installed on $env:COMPUTERNAME."
    Clear-Files
    Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) Completed removing $Name Successfully"
    Return "Success - $Name is not installed."
  }

Write-Log -message "$Name Uninstall string found to be: $UID "

Write-Log -message "Uninstalling $Name"
$UID = $uid.replace("MsiExec.exe /I","")

$result = (Start-process -FilePath msiexec.exe -argumentList "/X ""$UID"" /qn" -Wait).ExitCode
Write-log -message "Uninstall of $Name resulted in exit code: $result"

}
$UID = Get-Application
  If (!($UID)) {
    Write-Log -Message "Success - $Name has been removed from $env:COMPUTERNAME"
    Clear-Files
    Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) Completed removing $Name Successfully"
    Return "Success - $Name has been removed from $env:COMPUTERNAME"

} else {
    Write-log -message "Can not guarantee that $Name was removed please review" -Type ERROR
    Clear-Files
    Write-NewEventlog -eventid 7005 -message "$($MyInvocation.ScriptName) Could not verify removal of $Name"
    Return "$Name may still be installed please review $env:COMPUTERNAME and check file located in C:\Temp\Uninstall-Application.log"
}
