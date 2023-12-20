# Remove-TechUser

Remove-TechUser removes desired -ASG accounts from Active directory

## Syntax
```PowerShell
Remove-TechUser.ps1 [-UserName] <StringArray> [<CommonParameters>]
```
## Description

Removes one or more asg ad users from Active Directory

## Examples


###  Example 1 
```PowerShell
Remove-TechUser.ps1 -UserName 'CCalverley-ASG'
```

Removes CCalverley-ASG's active directory account.

###  Example 2 
```PowerShell
Remove-TechUser.ps1 -UserName 'CCalverley-ASG', 'David-ASG'
```

Removes CCalverley-ASG and David-ASG active directory accounts.