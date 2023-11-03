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
  [Parameter(Mandatory=$true)][string]$ServiceName,
  [Parameter(Mandatory=$true)][Int32]$Interval
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock
}

#I want to hash the service name and I want to add the date/time of last check and i want the interval
#I am thinking of utilizing the registry for this 
# set up registry

Write-Log -message 'Setting up monitor in registry'
Set-Location HKLM:
If(!(Test-Path .\software\asg\Internal-Monitor\$ServiceName)){
  New-Item .\software\asg\Internal-Monitor -Name $ServiceName -force
  New-ItemProperty -Path .\SOFTWARE\asg\Internal-Monitor\$ServiceName -Name Interval -Value $Interval -Force
  New-ItemProperty -Path .\SOFTWARE\asg\Internal-Monitor\$ServiceName -Name LastRun -Value $(Get-date -format s) -Force
  Pop-Location
} else {
  New-ItemProperty -Path .\SOFTWARE\asg\Internal-Monitor\$ServiceName -Name Interval -Value $Interval -Force
  New-ItemProperty -Path .\SOFTWARE\asg\Internal-Monitor\$ServiceName -Name LastRun -Value $(Get-date -format s) -Force
  Pop-Location
}

Write-Log -message 'Adjusting Script'
#create the scheduled task
$Script = @"

If (!(`$bootstraploaded)){
  Set-ExecutionPolicy Bypass -scope Process -Force
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  `$BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
  `$scriptblock = [scriptblock]::Create(`$BaseRepoUrl)
  Invoke-Command -ScriptBlock `$scriptblock
}


function WriteNew-Eventlog {
  param(
      [Parameter(Mandatory=`$True)][Int32]`$EventID,
      [Parameter(Mandatory=`$false)][string]`$EntryType = 'Information',
      [Parameter(Mandatory=`$true)][string]`$Message,
      [Parameter(Mandatory=`$false)][Int32]`$Category,
      [Parameter(Mandatory=`$False)][Int32[]]`$RawData = (10,20)
  )
  
      `$source = 'ASG-Monitoring'
      New-eventlog -Source `$source -LogName Application -ErrorAction SilentlyContinue
      Write-EventLog -LogName Application -Source `$source -eventid `$EventID -EntryType `$EntryType -message `$Message -Category `$Category -RawData `$RawData
      return
  }
  
  
`$Monitors = Get-ChildItem -Path HKLM:\SOFTWARE\asg\Internal-Monitor\
if ((Get-Item -Path 'C:\Temp\Watch-Service.log').CreationTime -lt (Get-Date).AddDays(-1)){
  Remove-Item -Path 'C:\Temp\Watch-Service.log' -Force
  }
Write-log -message '---------------New Run-----------------' 
foreach (`$monitor in `$monitors){
    `$service = ''
    `$MonitorInterval = `$monitor | Get-ItemPropertyValue -name Interval
    Write-Log -message "Interval is `$monitorinterval"
    `$monitorLastRun = `$monitor | Get-ItemPropertyValue -Name LastRun
    Write-Log -message "Interval is `$monitorLastRun"
    Write-Log -message "Checking datetime : `$(([datetime]::Parse(`$monitorLastRun)).addseconds(`$MonitorInterval))"
    if((Get-date) -gt (([datetime]::Parse(`$monitorLastRun)).addMinutes(`$MonitorInterval))) {
      Write-Log -message "`$monitor will run"
      Write-Log -message "Monitor Name is : `$(`$monitor.PSChildName)"
      #need to try next line and error out if service isn't found make a event log
      `$service = try {Get-service -Name `$monitor.PSChildName -ErrorAction stop} Catch {"Service `$(`$Service.name) does not exist"}
      If (`$service -eq "Service `$(`$Service.name) does not exist") {
        WriteNew-Eventlog -EventID 7001 -EntryType 'Error' -Message `$service
        Continue
      } else {
        Write-Log -message "`$(`$Service.name) is in `$(`$Service.Status) state"
        If (`$service.Status -ne 'Running'){
          Write-Log -message 'Restarting service'
          Try {`$service|Restart-service -Force -ErrorAction stop}
          Catch {
            Write-Log -message "Forcefully killing `$service"
            `$PID = try{Get-CimInstance -ClassName 'Win32_service' -Filter "Name LIKE '`$(`$Service.Name)'" -erroraction stop | Select-Object -ExpandProperty ProcessID} catch {'N/A'}
            if (`$PID -eq 'N/A'){WriteNew-Eventlog -EventID 7002 -EntryType 'Error' -Message `$error[0]; continue}
            Write-Log -message "PID found as `$PID"
            Write-Log -message 'Taskkilling process'
            Taskkill /f /pid `$PID
            Write-Log -message 'Restarting process'
            start-service -Name `$service.Name
          }
        if ((Get-service `$Service.name).Status -ne 'Running'){
          Write-Log -message "Could not start `$(`$Service.name)"
          WriteNew-Eventlog -EventID 7003 -EntryType 'ERROR' -Message "Could not start `$(`$Service.name) after stopped state"
        }else {
          Write-Log -message "Successfully restarted `$(`$Service.name)"
        }
      } else {
        Write-Log -message "`$(`$service.Name) is running"
      }
    } 
  } else {
    Write-Log -message "`$monitor Is not due - skipping"
  }
  Write-Log -Message "`$Monitor LastRun time is being set to `$(Get-date -format s)"
  `$Monitor | Set-ItemProperty -Name LastRun -value `$(Get-date -format s) -Force
}
"@

#I need to save this file somewhere
$filelocation = 'C:\ProgramData\ASG\Scripts'
$ScriptFileName = 'ServiceWatcher.ps1'
Write-Log -message "Saving Script to : $filelocation\$ScriptFileName"
if (!(Test-Path -LiteralPath $filelocation)) {
  New-Item -Path $filelocation -ItemType Directory
}
if (!(Test-Path -Path "$filelocation\$ScriptFileName")){
  New-item -Path "$filelocation\$ScriptFileName" -ItemType File
  Add-Content -Path "$filelocation\$ScriptFileName" -Value $Script
} else {
  set-content -Path "$filelocation\$ScriptFileName" -Value $script -Force
}
Write-Log -message 'Creating Scheduled Job'
#I need to make a scheduled task
$filelocation = 'C:\ProgramData\ASG\Scripts'
$ScriptFileName = 'ServiceWatcher.ps1'
#I need to make a scheduled task
$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.connect()
$rootFolder = $scheduleObject.GetFolder("\")
try {$rootFolder.CreateFolder("ASG")} catch {Write-Log -Message 'ASG Scheduled Task Folder Exists'}
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) 
$action = New-ScheduledTaskAction -Execute "Powershell" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$filelocation\$Scriptfilename`""
$User= "NT AUTHORITY\LOCAL SERVICE"
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable 
$ST = New-ScheduledTask -Action $action -Trigger $trigger  -Settings $settings 
try {Register-ScheduledTask ASG-Service-Monitor -InputObject $ST  -TaskPath asg - $User -Force} catch {Write-Log -message 'Scheduled task already exists, or errored out'}

#need to verify scheduled task creation.