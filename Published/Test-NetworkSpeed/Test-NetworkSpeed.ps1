<#
  .SYNOPSIS
  Return Speed test results on a computer in the background

  .DESCRIPTION
  Downloads / extracts / and runs speedtest and returns the results.
  
  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Test-NetworkSpeed.log  

  .EXAMPLE
  PS> .\Test-NetworkSpeed.ps1 
  Returns the results of Okaala's speedtest to the console and log file.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 4, 2023
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

$Url = 'https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-win64.zip'

$DownloadLocation = 'C:\temp\SPTest.zip'

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"

If (Test-Path 'C:\temp\SPTest\Speedtest.exe'){
  Write-log -message "File has already been downloaded and extracted, continuing without downloading and extracting."
} else {
  Write-log -message "Downloading and installing speedtest cli."
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $DownloadLocation
  Expand-Archive -literalpath $DownloadLocation -DestinationPath 'C:\temp\SPTest'
}
Write-log -message "Getting Speedtest Results."
$TestResults = & C:\temp\SPTest\Speedtest.exe --accept-license
Write-Log -Message '$($TestResults | Out-String)'

return $TestResults