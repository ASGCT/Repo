<#
  .SYNOPSIS
  Uses the computer itself to monitor it's own services - autofix's them if possible.

  .DESCRIPTION
  This script will create registry in the following registry location
    HKLM:\Software\asg\Internal-Monitor
  These items will be in the following format
    Key = Service Name
      Property Interval = The interval to check the service.
      Property LastRun = The last time it checked the service.

  This script will create the following Powershell script.
    C:\Programdata\asg\scripts\ServiceWatcher.ps1
  
  This script creates the following scheduled task
    Task Scheduler (Local)
      Task Scheduler Library
        ASG
          ASG-Service-Monitor

  The ServiceWatcher script reads the registry and gathers all target Services
    Then it loops through all services gathering their state and interval
      If the service is not running it will attempt to start the service
        If the service does not exist it creates an event log event id 7001 and moves on to the next service
        If the service is not running
          An attempt to restart service is made.
            If the service can not be simply restarted an attempt to forcefully kill the process is made
              If the service can not get the pid or kill the pid an event of 7002 will be thrown containing the error.
            The service is then attempted to be restarted.
          If the service is not started after that attempt an event log of 7003 will be thrown stating it could not start the service.
          Moves on to the next service
      Reports the service is running
    If the service is not due to be monitored it is skipped and that skip is logged
    Moves on to the next service
    If the service was due 
    logs the change to the registry for the last run time
    Changes the lastRun registry value
  
  .PARAMETER ServiceName
  The Service name you wish to monitor

  .PARAMETER Interval
  The time in minutes in which you want the monitor to run on this service.

  .INPUTS
  ServiceName
  Interval

  .OUTPUTS
  C:\ProgramData\ASG\Scripts\ServiceWatcher.ps1
  C:\ProgramData\ASG\Script-Logs\Watch-Service.log
  C:\ProgramData\ASG\Script-Logs\ServiceWatcher.log
  Task Scheduler > Task Scheduler Library > ASG > ASG-Service-Monitor
  Event Viewer > Application > Provider = ASG-Monitoring [Error Type]

  .EXAMPLE
  PS> .\Watch-Service.ps1 -ServiceName 'Windows Agent Service' -Interval 5
  Monitors the 'Windows Agent Service' every 5 minutes

  .EXAMPLE
  PS> .\Watch-Service.ps1 -ServiceName 'SQLService' -Interval 20
  Monitors the 'SqlService' every 20 minutes.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 03, 2023
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
if ((Get-Item -Path 'C:\ProgramData\ASG\Script-Logs\ServiceWatcher.log').CreationTime -lt (Get-Date).AddDays(-1)){
  Remove-Item -Path 'C:\ProgramData\ASG\Script-Logs\ServiceWatcher.log' -Force
  }
Write-log -message '---------------New Run-----------------' 
foreach (`$monitor in `$monitors){
    `$service = ''
    `$MonitorInterval = `$monitor | Get-ItemPropertyValue -name Interval
    Write-Log -message "Interval is `$monitorinterval"
    `$monitorLastRun = `$monitor | Get-ItemPropertyValue -Name LastRun
    Write-Log -message "Last Ran on: `$monitorLastRun"
    Write-Log -message "Checking datetime : `$(([datetime]::Parse(`$monitorLastRun)).addMinutes(`$MonitorInterval))"
    if((Get-date) -ge (([datetime]::Parse(`$monitorLastRun)).addMinutes(`$MonitorInterval))) {
      Write-Log -message "`$monitor will run"
      Write-Log -message "Monitor Name is : `$(`$monitor.PSChildName)"
      #need to try next line and error out if service isn't found make a event log
      `$service = try {Get-service -Name `$monitor.PSChildName -ErrorAction stop} Catch {"Service `$(`$Service.name) does not exist"}
      If (`$service -eq "Service `$(`$monitor.PSChildName) does not exist") {
        WriteNew-Eventlog -EventID 7001 -EntryType 'Error' -Message `$service
        Continue
      } else {
        Write-Log -message "`$(`$Service.name) is in `$(`$Service.Status) state"
        If (`$service.Status -notin ('Running', 'StartPending')){
          Write-Log -message 'Restarting service'
          Try {`$service|Restart-service -Force -ErrorAction stop}
          Catch {
            Write-Log -message "Forcefully killing `$service"
            `$MPID = try{Get-CimInstance -ClassName 'Win32_service' -Filter "Name LIKE '`$(`$Service.Name)'" -erroraction stop | Select-Object -ExpandProperty ProcessID} catch {'N/A'}
            if (`$MPID -eq 'N/A'){WriteNew-Eventlog -EventID 7002 -EntryType 'Error' -Message `$error[0]; continue}
            Write-Log -message "PID found as `$MPID"
            Write-Log -message 'Taskkilling process'
            Taskkill /f /pid `$MPID
            Write-Log -message 'Restarting process'
            start-service -Name `$service.Name
          }
        if ((Get-service `$Service.name).Status -notin ('Running', 'StartPending')){
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
    Continue
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
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable 
$ST = New-ScheduledTask -Action $action -Trigger $trigger -Principal $Principal -Settings $settings 
try {Register-ScheduledTask ASG-Service-Monitor -InputObject $ST  -TaskPath asg -Force} catch {Write-Log -message 'Scheduled task already exists, or errored out'}

Clear-Files