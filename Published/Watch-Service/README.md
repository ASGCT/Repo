# Watch-Service

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
  

## Syntax
```PowerShell
Watch-Service.ps1 [-ServiceName] <String> [-Interval] <String> [<CommonParameters>]
```
## Description

Uses the computer itself to monitor it's own services - autofix's them if possible.

## Examples


###  Example 1 
```PowerShell
Watch-Service.ps1 -ServiceName 'Windows Agent Service' -Interval 5
```

Monitors the 'Windows Agent Service' every 5 minutes

###  Example 2 
```PowerShell
Watch-Service.ps1 -ServiceName 'SQLService' -Interval 20
```

Monitors the 'SqlService' every 20 minutes.