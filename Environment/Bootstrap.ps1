
    function Global:Write-log {
        param(
            [Parameter(Mandatory=$false)][string]$Message,
            [Parameter(Mandatory=$False)][ValidateSet('Log','ERROR','Data')][String]$Type = 'Log'
        )
        Set-ExecutionPolicy Bypass -scope Process -Force
        Set-Location -LiteralPath 'C:\ProgramData\ASG'
        $MyLogName = "$($MyInvocation.ScriptName)"
        $LogName = (($MyLogName).Split('\')[$(($MyLogName).Split('\')).Count - 1]).Replace('.ps1','')
        $scriptLog = "$LogName.log"
        $Scriptlogpath = '.\log'
        if (!(Test-Path -LiteralPath 'C:\ProgramData\ASG\Logs')) {
            New-Item -ItemType Directory -Name $Scriptlogpath | Out-Null
        }
        if (!(Test-Path -LiteralPath "C:\ProgramData\ASG\Logs\$scriptLog")) {
            New-Item -ItemType File -Path $Scriptlogpath -Name $scriptLog | Out-Null
            $MyDate = Get-Date -Format s
            Add-Content -Path "$Scriptlogpath\$scriptLog" -Value "----------------------------------------------"
            Add-Content -Path "$Scriptlogpath\$scriptLog" -Value "$MyDate - $Type - $MyLogName "
            Add-Content -Path "$Scriptlogpath\$scriptLog" -Value "$MyDate - $Type - $Message"
        } else {
            $MyDate = Get-Date -Format s
            $Lastrun = ((Get-Content $Scriptlogpath\$scriptLog) | Select-Object -Index 2).Split(' ')
            $lastruncomparor = ([datetime]$lastrun[0]).AddMinutes(30)
            If ($MyDate -lt $lastruncomparor) {
                Add-Content -Path  "$Scriptlogpath\$scriptLog" -Value "----------------------------------------------"
                Add-Content -Path "$Scriptlogpath\$scriptLog" -Value "$MyDate - $Type - $MyLogName"
            }
            Add-Content -Path "$Scriptlogpath\$scriptLog" -Value "$MyDate - $Type - $Message"
        }
    }

    function global:Clear-Files {
        $MyLogName = "$($MyInvocation.ScriptName)"
        $LogName = (($MyLogName).Split('\')[$(($MyLogName).Split('\')).Count - 1]).Replace('.ps1','')
        if ((Test-Path "C:\Temp\$LogName")) {
            Remove-item -LiteralPath "C:\Temp\$LogName" -Force -Recurse
        }
    }

    $Global:bootstraploaded = $true
