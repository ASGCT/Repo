# Get-EventLogs

  This script will query Event viewer for any logs that fulfill specific criteria,
  You can filter by id, keyword, and Entry type.
  You can limit your results by setting a thresholdhours.

## Syntax
```PowerShell
Get-EventLogs.ps1 [-LogSource] <ValidateSet> [-EventID] <Int> [-EntryType] <ValidateSet> [-KeyWord] <string> [-ThresholdHours] <Int> [<CommonParameters>]
```
## Description

Get specific event logs

## Examples


###  Example 1 
```PowerShell
Get-EventLogs.ps1 -LogSource Application
```

Exports all application logs that have occurred in the past 24 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

###  Example 2 
```PowerShell
Get-EventLogs.ps1 -LogSource Application -EventID 7010 -ThresholdHours 72
```

Exports all application event logs with an id of 7010 that have occurred in the past 72 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

###  Example 3
```PowerShell
Get-EventLogs.ps1 -LogSource Security -EventType 'Audit Failure' -ThresholdHours 36
```

Exports all Security event logs with an event type of Audit Failure that have occurred in the past 36 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

###  Example 4
```PowerShell
Get-EventLogs.ps1 -LogSource Security -EventType 'Audit Failure' -ThresholdHours 36
```

Exports all Security event logs with an event type of Audit Failure that have occurred in the past 36 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv  
Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.