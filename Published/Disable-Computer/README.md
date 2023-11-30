# Disable-Computer

This Script should wipe out every partition on every drive and replace it with a single clean partition.

## Syntax
```PowerShell
Disable-Computer.ps1 [<CommonParameters>]
```
## Description

This script renders a computer useless until you re-install windows

## Examples


###  Example 1 
```PowerShell
Disable-Computer.ps1 
```

Grabs the Install-DNSFilter.ps1 file from the repo and executes it on a target machine.

###  Example 2 
```PowerShell
Execute-RepoScript.ps1 -FileName 'Install-SkykickOutlookAssistant' -arguments -organizationKey iouerdjgfo987845t=
```

Grabs the Install-SkykickOutlookAssistant.ps1 file from the repo and executes it on a target machine using the organization key iouerdjgfo987845t=