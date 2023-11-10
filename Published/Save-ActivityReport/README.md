# Save-ActivityReport

  This script will determine if a user had moved the mouse or touched a key and tell you how long it has been since this has happened.
  This should be a scheduled - re-ocurring task in the rmm.

## Syntax
```PowerShell
Save-ActivityReport.ps1 [<CommonParameters>]
```
## Description

Saves a log of last Non-idle actions on a computer

## Examples


###  Example 1 
```PowerShell
Save-ActivityReport.ps1 
```

Saves the log file to the appropriate container for review
