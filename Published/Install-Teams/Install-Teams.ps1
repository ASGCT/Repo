#requires -version 5
<#
.SYNOPSIS
    Install Microsoft Teams for All users on computer.
.DESCRIPTION
    This script will utilize the Microsoft Teams Machine Wide Installer to install Teams for all users.
.INPUTS
    None
.OUTPUTS
    Console [String]
.NOTES
    Version:        1.0
    Author:         Chris Calverley
    Creation Date:  09/05/2023
    Purpose/Change: Initial script development
.EXAMPLE
    Install-Teams.ps1
    Installs teams for all users on the target machine.
#>

[CmdletBinding()]
Param()

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock
    Clear-Files
}
#N-Able does n
if (Test-Path $DownloadLocation) {
    Remove-Item $DownloadLocation -Force
}
#use the teams machine wide installer
$BaseName = 'Teams_MWI'
$FileName = "$BaseName.msi"
$DownloadLocation = ".\$BaseName"

if ([Environment]::Is64BitProcess) {
    $Installer = 'https://statics.teams.microsoft.com/production-windows-x64/1.1.00.14359/Teams_windows_x64.msi'
} else {
    $Installer = 'https://statics.teams.microsoft.com/production-windows/1.1.00.14359/Teams_windows.msi'
}

If(!(Test-Path $DownloadLocation)) {
    New-Item -ItemType Directory -Name "$DownloadLocation" -Force
}
Write-Log -Message 'Downloading Teams MWI' -Type LOG
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing -Uri $Installer -OutFile "$DownloadLocation\$FileName"

& msiexec.exe /I "C:\Temp\$BaseName\$FileName" /qn /Norestart ALLUSERS=1

#Verify
if (!(Test-Path "C:\Program Files\Teams Installer") -and (!(Test-Path "C:\\Program Files (x86)\Teams Installer"))) {
    Write-Log -message "Installation of Microsoft Teams failed with exit code: $ExitCode.  Cannot Continue" -Type ERROR
    $status = 'Failed'

} else {
    Write-Log -message 'Microsoft Teams has successfully Installed'
    $Status = 'Success'

}
#Clean-up
Write-Log -Message "Cleaning up - Removing $DownloadLocation"
if (Test-Path $DownloadLocation) {
    Remove-Item $DownloadLocation -Force
}
$MyLogName = "$($MyInvocation.ScriptName)"
$LogName = (($MyLogName).Split('\')[$(($MyLogName).Split('\')).Count - 1]).Replace('.ps1','')
Write-Log -Message "Cleaning up - Removing $LogName"

Clear-Files

Return $Status