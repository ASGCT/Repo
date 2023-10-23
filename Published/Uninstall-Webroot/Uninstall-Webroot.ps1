<#
  .SYNOPSIS
  Uninstalls Webroot

  .DESCRIPTION
  This Script will uninstall webroot from a target machine. 

  .OUTPUTS
  System.String
  C:\Temp\Uninstall-Webroot.log  

  .EXAMPLE
  PS> .\Uninstall-Webroot.ps1 
  Uninstalls Webroot 


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



$guids = Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct | Where-Object {$_.displayName -like '*Webroot*'} | Select-object -ExpandProperty instanceGuid

foreach ($guid in $guids) {
  Remove-WmiObject -path \\localhost\ROOT\SecurityCenter2:AntiVirusProduct.instanceGuid="$guid"
}

cmd /c 'sc delete WRSkyClient'

cmd /c 'sc delete WRCoreService'

cmd /c 'sc delete WRSVC'

cmd /c 'del /f "C:\windows\system32\drivers\wrkrn.sys"'

cmd /c 'del /f "C:\windows\system32\wruser.dll"'

cmd /c 'del /f "C:\program files\webroot\*.* /y'

cmd /c 'del /f "C:\Program Files (x86)\Webroot\*.*" /y'

cmd /c 'del /f "C:\ProgramData\WRCore\*.*" /y'

cmd /c 'del /f "C:\ProgramData\WRData\*.*" /y'

cmd /c 'rd /s /q "C:\ProgramData\WRData\"'

cmd /c 'rd /s /q "C:\Program Files\Webroot\"'

cmd /c 'rd /s /q "C:\Program Files (x86)\Webroot\"'

cmd /c 'rd /s /q "C:\ProgramData\WRCore\"'

cmd /c 'reg Delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WRUNINST" /f'

cmd /c 'reg Delete "HKLM\SOFTWARE\WRData" /f'

cmd /c 'reg Delete "HKLM\SYSTEM\ControlSet001\services\WRSVC" /f'

cmd /c 'reg Delete "HKLM\SYSTEM\ControlSet002\services\WRSVC" /f'

cmd /c 'reg Delete "HKLM\SYSTEM\CurrentControlSet\services\WRSVC" /f'

cmd /c 'reg delete "HKLM\SOFTWARE\WOW6432Node\Webroot" /f'


$Path = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "*Webroot*" } | Select-Object -ExpandProperty PSPath
Remove-item -Path $Path -Force

cmd /c 'C:\"Program Files (x86)"\webroot\wrsa.exe -Uninstall'
Start-Sleep  -Seconds 30