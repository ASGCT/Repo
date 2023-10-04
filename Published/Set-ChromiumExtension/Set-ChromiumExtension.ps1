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
  # Parameter help description
  [Parameter(Mandatory = $true)]
  [String]
  $ExtensionId
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

write-log -message "Installing Extension $ExtensionID"

$regKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
if(!(Test-Path $regKey)){
  New-Item $regKey -Force
  Write-Log -message "Created Reg Key $regKey"
}
$extensionsList = New-Object System.Collections.ArrayList
    $number = 0
    $noMore = 0
    do{
        $number++
        Write-Log -message "Pass : $number"
        try{
            $install = Get-ItemProperty $regKey -name $number -ErrorAction Stop
            $extensionObj = [PSCustomObject]@{
                Name = $number
                Value = $install.$number
            }
            $extensionsList.add($extensionObj) | Out-Null
            Write-Log -message "Extension List Item : $($extensionObj.name) / $($extensionObj.value)"
        }
        catch{
            $noMore = 1
        }
    }
    until($noMore -eq 1)
    $extensionCheck = $extensionsList | Where-Object {$_.Value -eq $extensionId}
    if($extensionCheck){
        $result = "Extension Already Exists"
        Write-Log -message "Extension Already Exists"
    }else{
        $newExtensionId = $extensionsList[-1].name + 1
        New-ItemProperty HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist -PropertyType String -Name $newExtensionId -Value $extensionId
        Write-Log -message 'Installed'
        $result = "Installed"
    }
Clear-Files
$result