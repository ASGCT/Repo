# New-TechUser

New-TechUser.ps1 will create a new asg user for a domain controller and assign the available Duo and VPN groups if they exist.

## Syntax
```PowerShell
New-TechUser.ps1 [-FirstName] <String> [-LastName] <String> [-Password] <SecureString> [<CommonParameters>]
```
## Description

Create a New Technician user for Clients.

## Examples


###  Example 1 
```PowerShell
New-TechUser.ps1 -FirstName 'Chris' -LastName 'Calverley' -Password [SecureString]
```

Creates a new user with the display name Chris Calverley, returns the sam account name to the console, Writes all information to the log.

