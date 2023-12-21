# Set-UserPassword

  Set-UserPassword.ps1 will determine a user's existance, then set that user's password to the requested password, it will optionally set that password
  to never expire, optionally unlock a locked account, and optionally sync to Office365

## Syntax
```PowerShell
Set-UserPassword.ps1 [-UserName] <String> [-Password] <SecureString> [-NeverExpire] [-Unlock] [-Sync] [<CommonParameters>]
```
## Description

Set a users password, reset the account lockout state, optionally set the password to never expire, and optionally sync to o365

## Examples


###  Example 1 
```PowerShell
Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] 
```

  Simply sets ccalverley-asg's account password to the password provided.

###  Example 2 
```PowerShell
Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock
```

  Sets ccalverley-asg's account password to the provided password and unlocks the account.

###  Example 3 
```PowerShell
Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock -NeverExpire
```

 Sets ccalverley-asg's account password to the provided password, unlocks the account, and sets the password to never expire.

###  Example 4 
```PowerShell
Set-UserPassword.ps1 -UserName 'CCalverley-asg' -Password [SecureString] -Unlock -NeverExpire -Sync
```

  Sets ccalverley-asg's account password to the provided password, unlocks the account, sets the password to never expire, finally Syncing ad with Office 365.    