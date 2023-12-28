<#
  .SYNOPSIS
  Returns X largest files in a path.

  .DESCRIPTION
  Get-LargeFiles will return X Largest files in path Y, Where X is the Limit parameter defaulted to 10 and Y is the desired path defaulted to C:
  
  .PARAMETER TargetPath
  Specifies the target path to look in Defaulted to C:

  .PARAMETER Limit
  Specifies the Amount of Large files you wish to return, defaulted to 10.

  .OUTPUTS
  System.String
  C:\ProgramData\ASG\Script-Logs\Get-LargeFiles.log  

  .EXAMPLE
  PS> .\Get-LargeFiles.ps1 
  Returns the 10 Largest files found on the C drive.

  .EXAMPLE
  PS> .\Get-LargeFiles.ps1 -TargetPath 'D:\' -Limit 20
  Returns the 20 Largest files found on the D drive.

  .EXAMPLE
  PS> .\Get-LargeFiles.ps1 -TargetPath 'C:\Users' -Limit 20
  Returns the 20 Largest files found recursively in C:\Users.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  December 28, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False, Position = 0)][System.IO.FileInfo]$TargetPath = 'C:\',
  [Parameter(Mandatory=$False, Position = 1)][Int]$Limit = 10
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

Write-Log -message "Getting Large files in: $TargetPath"

$LargeFiles = Get-ChildItem $TargetPath -r -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object FullName, Length -first $Limit

$BigFiles += Foreach ($file in $LargeFiles) {
  [PSCustomObject]@{
    File = $file.FullName
    SizeGB = $File.Length / 1GB
  }

}
Write-Log -message "Found the following Large Files: `r $($BigFiles | Out-String)"
Clear-Files
Return "Found the following Large Files: `r $($BigFiles | Out-String)"