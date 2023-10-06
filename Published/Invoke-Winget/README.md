# Invoke-Winget

Installs, Uninstalls, or Updates a winget package

## Syntax
```PowerShell
Invoke-Winget.ps1 [-action] <String> [<-all (Upgrade only)>] [-PackageID] <String> [-AdditionalInstallArgs] <String> [<CommonParameters>]
```
## Description

Installs, Updates, or Removes a winget package on a target from the system account.

## Examples


###  Example 1 
```PowerShell
Invoke-Winget.ps1 -Action Install -PackageID LIGHTNINGUK.ImgBurn
```

Installs Imgburn on a target machine not silently.

###  Example 2 
```PowerShell
Invoke-Winget.ps1 -Action Uninstall -PackageID LIGHTNINGUK.ImgBurn
```

Uninstalls ImgBurn silently on a target machine.

###  Example 3
```PowerShell
Invoke-Winget.ps1 -Action Upgrade -PackageID LIGHTNINGUK.ImgBurn
```

Upgrades ImgBurn silently on a target machine.

###  Example 4
```PowerShell
Invoke-Winget.ps1 -Action Upgrade -all
```

Upgrades all packages on a target machine.