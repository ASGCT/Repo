# Get-LargeFiles

Get-LargeFiles will return X Largest files in path Y, Where X is the Limit parameter defaulted to 10 and Y is the desired path defaulted to C:

## Syntax
```PowerShell
Get-LargeFiles.ps1 [-TargetPath] <String> [-Limit] <Int> [<CommonParameters>]
```
## Description

Returns X largest files in a path.

## Examples


###  Example 1 
```PowerShell
Get-LargeFiles.ps1 
```

Returns the 10 Largest files found on the C drive.

###  Example 2 
```PowerShell
Get-LargeFiles.ps1 -TargetPath 'D:\' -Limit 20
```

Returns the 20 Largest files found on the D drive.

###  Example 3 
```PowerShell
Get-LargeFiles.ps1 -TargetPath 'C:\Users' -Limit 20
```

Returns the 20 Largest files found recursively in C:\Users.

