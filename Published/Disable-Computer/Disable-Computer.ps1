<#
  .SYNOPSIS
  This script renders a computer useless until you re-install windows

  .DESCRIPTION
  This Script should wipe out every partition on every drive and replace it with a single clean partition.

  .INPUTS
  InstanceID (Which can be found in the software list contained in the ()'s for the instance)  

  .EXAMPLE
  PS> .\Disable-Computer.ps1 
  Removes all partitions on all drives and replaces them, rendering a computer useless.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 30, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)][string]$userName,
  [Parameter(Mandatory=$False)][Switch]$Force

)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}
if (!($userName) -or !($Force)) {
  Throw "For Safety Sake you must provide your username and the -Force parameter."
} else {
  $disks = Get-Disk
  foreach ($disk in $disks) {
      Get-Disk $disk.Number | Clear-Disk -RemoveData -Confirm:$false
      New-Partition -DiskNumber $disk.Number -UseMaximumSize
      $partition = Get-Partition -DiskNumber $disk.Number
      Get-Partition -DiskNumber $disk.Number -PartitionNumber $partition | Format-Volume -FileSystem NTFS
      Set-partition -PartitionNumber $partition.PartitionNumber -NewDriveLetter U
  }
}
