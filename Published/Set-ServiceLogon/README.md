# Set-ServiceLogon

  Sets the logon as value for a specified service if desired, 
  Resets all services using that logon credential if no service is specified.

## Syntax
```PowerShell
Set-ServiceLogon.ps1 [-LogonAs] <String> [-Password] <SecureString> [-ServiceNames] <StringArray> [<CommonParameters>]
```
## Description

Sets the logon as value for a service

## Examples


###  Example 1 
```PowerShell
Set-ServiceLogon.ps1 -LogonAs 'WAD\tech.support' -Password [Secure.String]
```

Checks for all services where the logonas name is set to 'WAD\tech.support' and sets the credentials to the new password.

###  Example 2 
```PowerShell
Set-ServiceLogon.ps1 -LogonAs 'WAD\tech.support' -Password [Secure.String] -ServiceNames 'testservice','testservice1'
```

Sets 'testservice' and 'testservice1' logon credentials to the logonas name and password.