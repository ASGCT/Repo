# New-LocalUserAccount

New-LocalUserAccount adds a local user account, either sets a password or sets the account to no password, Allows for setting of password never expires, Optional descriptions available
  Sets a password to Never expire if desired, and assigns that user to designated groups.

## Syntax
```PowerShell
New-LocalUserAccount.ps1 [-UserName] <String> [-Password] <SecureString> [-PasswordNeverExpires] [-Description] <String> [-UserMayNotChangePassword] [-Description] <StringArray> [<CommonParameters>]
```
## Description

Adds a local account to a target computer, assigns that user to requested groups.

## Examples


###  Example 1 
```PowerShell
New-LocalUserAccount.ps1 -UserName 'Calverley' -Password <SecureString> -PasswordNeverExpires -UserMayNotChangePassword -Groups 'Admin', 'Remote D'
```

Adds the user 'Calverley' to the local users group, sets the password to the secure password, sets the password to never expire and never change.
  Then adds 'Calverley' to the Administrators, and the Remote Desktop Users Groups.

###  Example 2 
```PowerShell
New-LocalUserAccount.ps1 -UserName 'Calverley' -Description 'Generic log in account' -Groups 'Users', 'power U'
```

Creates a passwordless account 'Calverley' with a description of 'Generic Log in account and adds Calverley to the Users and Power users groups.