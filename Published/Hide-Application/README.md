# Hide-Application

Apply a registry key to hide an application from removal.

## Syntax
```PowerShell
Hide-Application.ps1 [-Name] <String> [<CommonParameters>]
```
## Description

Give the ability to hide an installation from removal

## Examples


###  Example 1 
```PowerShell
Hide-Application.ps1 -Name 'Windows Agent'
```

Hides the Windows Agent application from the software list in windows preventing it from being removed.

