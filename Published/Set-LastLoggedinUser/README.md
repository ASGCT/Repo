# Set-LastLoggedinUser

Will set the last logged in user on a target machine

## Syntax
```PowerShell
Set-LastLoggedinUser.ps1 [-User] <String> [-DisplayName] <string> [-Domain] <Switch> [<CommonParameters>]
```
## Description

Sets the last logged in user on a computer

## Examples


###  Example 1 
```PowerShell
Set-LastLoggedinUser.ps1 -User ccalverley -DisplayName 'Chris Calverley'
```

Sets the local account ccalverley as the last logged in user

###  Example 2 
```PowerShell
Set-LastLoggedinUser.ps1 -User ccalverley  -DisplayName 'Chris Calverley' -Domain
```

Sets the machine domain account for ccalverley to the last logged in user