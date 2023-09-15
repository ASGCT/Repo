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
  [parameter(Mandatory=$true)][ValidateSet('Install','Upgrade','Uninstall')][string]$Action,
  [parameter(Mandatory=$false)][Validateset('ID','Name')][string]$Type = 'ID',
  [parameter(Mandatory=$true)][string]$Item
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

#ensure that psgallery is trusted.

$Env:PATH += "; C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.20.2201.0_x64__8wekyb3d8bbwe"
#check for modules
try {Get-WinGetVersion} 
Catch {Write-log -message 'Winget is not installed, installation may take time' -type Log 

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name psgallery -InstallationPolicy Trusted
Install-Module -Name NuGet -Force  
Install-Module -Name Microsoft.WinGet.Client -Force
  #WebClient
$dc = New-Object net.webclient
$dc.UseDefaultCredentials = $true
$dc.Headers.Add("user-agent", "Inter Explorer")
$dc.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")

#temp folder
$InstallerFolder = $(Join-Path $env:ProgramData CustomScripts)
if (!(Test-Path $InstallerFolder))
{
New-Item -Path $InstallerFolder -ItemType Directory -Force -Confirm:$false
}
	#Check Winget Install
	Write-Log -message "Checking if Winget is installed" 
	$TestWinget = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.DesktopAppInstaller"}
	If ([Version]$TestWinGet. Version -gt "2022.506.16.0") 
	{
		Write-Log -message "WinGet is Installed"
	}Else 
		{
		#Download WinGet MSIXBundle
		Write-Log -message "Not installed. Downloading WinGet..." 
		$WinGetURL = "https://aka.ms/getwinget"
		$dc.DownloadFile($WinGetURL, "$InstallerFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
		
		#Install WinGet MSIXBundle 
		Try 	{
			Write-Log -message "Installing MSIXBundle for App Installer..." 
			Add-AppxProvisionedPackage -Online -PackagePath "$InstallerFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -SkipLicense 
			Write-Log -Message "Installed MSIXBundle for App Installer"
			}
		Catch {
			Write-Log -message "Failed to install MSIXBundle for App Installer..." -Type ERROR
			} 
		}
  #winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --force
}
Import-module microsoft.winget.client
Get-WinGetVersion
Switch ($Action) {
  'Install' {
      $arugment = 'Install '
  }
  'Upgrade' {
      $arugment = 'Upgrade '
  }
  'Uninstall' {
      $arugment = 'Uninstall '
  }
  default {
    Write-log -message 'ERROR : An Unhandled exception has occurred' -type ERROR
    throw 'ERROR : An Unhandled exception has occurred'
  }
}

If ($type -eq 'ID') {
  $argument = "$argument--ID "
}

<# Available CMDlets
Get-WinGetVersion 
Find-WinGetPackage 
Get-WinGetPackage 
Get-WinGetSource 
Install-WinGetPackage 
Uninstall-WinGetPackage 
Update-WinGetPackage 
Get-WinGetUserSettings 
Set-WinGetUserSettings 
Test-WinGetUserSettings 
Assert-WinGetPackageManager 
Repair-WinGetPackageManager
#>