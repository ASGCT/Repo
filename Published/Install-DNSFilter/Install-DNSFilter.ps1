#requires -version 5
<#
.SYNOPSIS
    Install the DNSFilter Application on target machines silently
.DESCRIPTION
    Takes a client specific site key -SiteKey and a Whitelabel switch.
    To determine if -Whitelabel should be on or off utilize the file basename
    If the msi file is DNS_Agent_Setup then -WhiteLabel should be true.
    If the msi file is DNSFilter_Agent_Setup then -Whitelabel should be false.
    Script then downloads the desired installation media and runs the file in the background.  
.PARAMETER SiteKey
    SiteKey is used to transfer the client specific site key to the installation.
.PARAMETER WhiteLabel
    Whitelabel is used to determine the package file name for the installation.
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Chris Calverley
    Creation Date:  08/24/2023
    Purpose/Change: Initial script development
 
.EXAMPLE
    Install-DnsFilter.ps1 -SiteKey 'sjdifgngjglg'
    Installs the Dnsfilter application using the Non-whitelabel package name.
.EXAMPLE
    Install-DnsFilter.ps1 -SiteKey 'sjdifgngjglg' -Whitelabel
    Installs the Dnsfilter application using the whitelabel package name.
#>
#ToDo: Obtain the agent file download location and input that in line 50.
#ToDo: Test and verify installation.
[CmdletBinding()]
Param(
        [Parameter(Mandatory=$true)][String]$SiteKey,
        [Parameter(Mandatory=$False)][Switch]$WhiteLabel
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$Package = Get-Package 'DNSFilterAgent' -ErrorAction SilentlyContinue

If ($Package) {
    Write-Log -message 'DNSFilter is installed'
    Write-NewEventlog -eventid 7005 -EntryType 'Error' -message "$($MyInvocation.ScriptName) Stopped because DNSFilter is already Installed"
    Return 'Already Installed'
}

#Determine WhiteLabel
If ($WhiteLabel) {
    $BaseName = 'DNS_Agent_Setup'
} else {
    $BaseName = 'DNSFilter_Agent_Setup'
}
Write-Log -message "Basename is : $BaseName"
#get bitness
if (!([Environment]::Is64BitProcess)){
    $BaseName = "$BaseName" + '_X86'
}
Write-log -message "Verified basename is : $Basename"
$FileName = "$BaseName.msi"
$weburl = "https://download.dnsfilter.com/User_Agent/Windows/$FileName"
Write-log -message "WebUrl is : $WebUrl"
$DownloadLocation = ".\$BaseName"
Write-log -message "Downloading to  : $DownloadLocation"
If(!(Test-Path $DownloadLocation)) {
    New-Item -ItemType Directory -Name "$DownloadLocation" -Force
}
#Force tls 1.2 and Download file
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing -Uri $weburl -OutFile "$DownloadLocation\$FileName"
#Execute file
Write-Log -Message "Installing"
msiexec.exe /qn /i "C:\Temp\$BaseName\$FileName" NKEY="$SiteKey"

Write-Log -Message "Verifying..."
Start-Sleep -Seconds 20
$Package = Get-Package 'DNSFilterAgent' -ErrorAction SilentlyContinue

If ($Package) {
    Write-Log -message 'DNSFilter is installed'
    Write-NewEventlog -eventid 7010 -message "$($MyInvocation.ScriptName) Completed Successfully"
    Clear-Files
    Return 'Installed'
} else {
    Write-Log -message 'DNSFilter Could not be installed' -type ERROR
    Write-NewEventlog -eventid 7005 -message "$($MyInvocation.ScriptName) Could not install DNSFilter"
    Clear-Files
    Return 'Failed'
}
