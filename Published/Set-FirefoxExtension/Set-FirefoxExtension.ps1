<#
  .SYNOPSIS
  Install extensions on firefox browsers

  .DESCRIPTION
  Adds an extension to the Firefox browser
  
  .PARAMETER ExtensionUrl
  right-click the download button in the app store and select copy link address

  .INPUTS
  ExtensionUrl

  .OUTPUTS
  System.String
  C:\Temp\Set-FirefoxExtension.log

  .EXAMPLE
  PS> .\Set-FirefoxExtension.ps1 -ExtensionUrl https://addons.mozilla.org/firefox/downloads/file/4168788/1password_x_password_manager-2.15.1.xpi
  Installs 1Password on firefox browsers.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  October 04, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  # Parameter help description
  [Parameter(Mandatory=$true)]
  [String[]]
  $ExtensionUrl

)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

$extensionPath = 'C:\Temp\Firefox-Extensions'

If (!(Test-path $extensionPath)){
  New-Item $extensionPath -ItemType Directory -force | Out-Null
}

Foreach ($url in $ExtensionUrl) {
  $Url -match '(?<=/)(?<ExtensionName>[^/]+)(?=\?)'
  $Extension = $matches['ExtensionName']

  Invoke-WebRequest -Uri $url -OutFile "$extensionPath\$Extension"
}

Get-ChildItem -Path $ExtensionPath | Foreach-Object { $NewName = $_.FullName -replace ".xpi", ".zip" 
Copy-Item -Path $_.FullName -Destination $NewName }

Expand-Archive -Path (Get-ChildItem $ExtensionPath |
Where-Object { $_.Extension -eq '.zip'} | Select-Object -ExpandProperty FullName) -DestinationPath $ExtensionPath

$jsonContent = Get-Content "$ExtensionPath\manifest.json" | ConvertFrom-Json
$NewValues = $jsonContent.applications.gecko.id

Rename-Item -Path $ExtensionPath\$($matches['ExtensionName']) -NewName "$NewValues.xpi"
Remove-Item -Path $ExtensionPath -Exclude *.xpi -Recurse -Force

If([environment]::Is64BitOperatingSystem) {
  If (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") {
          
    $regKey = "HKLM:\Software\Mozilla\Firefox\Extensions"
    New-ItemProperty -Path $regKey -Name $authorValue -Value "$ExtensionPath\$authorValue.xpi" -PropertyType String
  } Else {
          
          $regKey = "HKLM:\Software\Wow6432Node\Mozilla\Firefox\Extensions"
          
          New-ItemProperty -Path $regKey -Name $authorValue -Value "$ExtensionPath\$authorValue.xpi" -PropertyType String
      }

} else {
  $regKey = "HKLM:\Software\Mozilla\Firefox\Extensions"
      New-ItemProperty -Path $regKey -Name $matches['ExtensionName'] -Value "$ExtensionPath\$($matches['ExtensionName'])" -PropertyType String
  
}
