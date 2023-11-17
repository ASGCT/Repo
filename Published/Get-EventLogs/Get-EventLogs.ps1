<#
  .SYNOPSIS
  Get specific event logs

  .DESCRIPTION
  This script will query Event viewer for any logs that fulfill specific criteria,
  You can filter by id, keyword, and Entry type.
  You can limit your results by setting a thresholdhours.
  
  .PARAMETER LogSource
  Specify the source of the log you wish to query from 'Application','Security','Setup','System'

  .PARAMETER EventID
  Specify the event ID you wish to query if desired.

  .PARAMETER EntryType
  Specify the type of log you wish to query from 'Information', 'Error', 'Warning', 'Critical', 'Audit Failure', 'Audit Success'

  .PARAMETER Keyword
  Specify a keyword or words you wish to query in the message text. The words must be found in the message body in exactly that order if using multiple words.

  .PARAMETER ThresholdHours
  Specify the threshold you would like to limit your search to, this is defaulted to 24 hours, so the default action of this script is to look back 24 hours from the running date/time.
  
  .INPUTS
  Available parameters.

  .OUTPUTS
  System.String
  C:\ProgramDat\ASG\DataFiles\Get-EventLogs.csv  
  C:\ProgramDat\ASG\DataFiles\Get-EventLogs.csv.bak
  C:\ProgramDat\ASG\Script-Logs\Get-EventLogs.Log 

  .EXAMPLE
  PS> .\Get-EventLogs.ps1 -LogSource Application
  Exports all application logs that have occurred in the past 24 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
  Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

  .EXAMPLE
  PS> .\Get-EventLogs.ps1 -LogSource Application -EventID 7010 -ThresholdHours 72
  Exports all application event logs with an id of 7010 that have occurred in the past 72 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
  Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.
  
  .EXAMPLE
  PS> .\Get-EventLogs.ps1 -LogSource Security -EntryType 'Audit Failure' -ThresholdHours 36
  Exports all Security event logs with an entry type of Audit Failure that have occurred in the past 36 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv
  Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

  .EXAMPLE
  PS> .\Get-EventLogs.ps1 -LogSource Security -EntryType 'Audit Failure' -ThresholdHours 36
  Exports all Security event logs with an entry type of Audit Failure that have occurred in the past 36 hours to c:\programdata\asg\Datafiles\Get-Eventlogs.csv  
  Returns the first found log time, the last found log time, the total amount of logs of that type, and the message content of the last found log.

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 16, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true, HelpMessage = 'Which Windows log do you wish to target',Position = 0)]
  [ValidateSet ('Application','Security','Setup','System')][string]$LogSource,

  [Parameter(Mandatory = $false, HelpMessage = 'The Identifier of the event',Position = 1)]
  [int]$EventID = $null,

  [Parameter(Mandatory = $false, HelpMessage = 'The level in Application, setup, and system, the keyword in Security',Position = 2)]
  [ValidateSet ('Information', 'Error', 'Warning', 'Critical', 'Audit Failure', 'Audit Success')]
  [string]$EntryType = $null,


  [Parameter(Mandatory = $false, HelpMessage = 'Enter a keyword found in the message of the log',Position = 3)]
  [string]$KeyWord = $Null,

  [Parameter(Mandatory = $false, HelpMessage = 'Enter the hours you wish to go back to query',Position = 3)][int]$thresholdhours = 24
)

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}

#no options return everything in threshold hours
If (!($EventID) -and !($EntryType) -and !($keyword)) {
  Write-log -message "Getting all Events within the last $thresholdhours hours"
  $list = Get-EventLog -LogName $LogSource | Where-Object { $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#EventID, returns all eventid results in threshold hours
elseif ($EventID -and !($EntryType) -and !($KeyWord)) {
  Write-log -message "Getting all Events with EventID $EventID within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.EventID -eq "$EventID" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#eventid and entrytype gives all warnings or criticals or information etc.
elseif ($EventID -and $EntryType -and !($KeyWord)) {
  Write-log -message "Getting all Events with EventID $EventID and an Entrytype of $EntryType within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.EventID -eq "$EventID" -and $_.EntryType -eq "$EntryType" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#eventID and Keyword looks for all eventid's with a keyword in the message.
elseif ($EventID -and !($EntryType) -and $KeyWord) {
  Write-log -message "Getting all Events with EventID $EventID and the word $KeyWord in the Message within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.EventID -eq "$EventID" -and $_.Message -Like "*$KeyWord*" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#entrytype and Keyword looks for all warnings with a keyword or all whatever with a keyword
elseif (!($EventID) -and $EntryType -and $KeyWord) {
  Write-log -message "Getting all Events with the entrytype of $EntryType and the word $KeyWord in the Message within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.EntryType -eq "$EntryType" -and $_.Message -Like "*$KeyWord*" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#If only an entry type is provided give all of that type within the threshold
elseif (!($eventID) -and $EntryType -and !($KeyWord)) {
  Write-log -message "Getting all Events with the entrytype of $EntryType within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.EntryType -eq "$EntryType" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
} 
#If only a keyword is provided return all with that word in the message withing the threshold.
elseif (!($EventID) -and !($EntryType) -and $KeyWord) {
  Write-log -message "Getting all Events with the word $KeyWord in the Message within the last $thresholdhours hours"
  $List = Get-EventLog -LogName $LogSource | Where-Object {$_.Message -Like "*$KeyWord*" -and $_.TimeGenerated -gt (Get-Date).AddHours(-$thresholdhours) }
}
$Loglocation = 'C:\ProgramData\ASG\DataFiles'
$ScriptName = "$($MyInvocation.ScriptName)"
$ForScriptName = (($ScriptName).Split('\')[$(($ScriptName).Split('\')).Count - 1]).Replace('.ps1','')
$FileName = "$ForScriptName.CSV"
If ($list.count -gt 0) {
  $first = $List | Select-Object -Last 1
  $last = $list | Select-Object -First 1
  Write-Log -message "Found eventID $($first.EventID) first at : $($first.TimeGenerated)"
  Write-log -message "Total events: $($list.count)"
  Write-log -message "The last event of eventID $($first.EventID) was found at : $($Last.TimeGenerated)"
  Write-log -message "The last event of eventID $($last.EventID) message body : `r$($Last.Message)"
  write-log -message "Exporting query to $loglocation"
  if (!(Test-Path -LiteralPath $Loglocation)) {
    New-item -Path $loglocation -ItemType Directory -Force
  }
  if (Test-Path -LiteralPath "$loglocation\$fileName" ) {
    if (Test-Path -LiteralPath "$loglocation\$fileName.bak") {
      remove-item -Path "$loglocation\$fileName.bak" -Force
    }
    rename-item -Path "$loglocation\$fileName" -NewName "$loglocation\$fileName.bak"
  }
  $list | Export-Csv -LiteralPath $Loglocation\$FileName
  Clear-Files
  return "Found eventID $($first.EventID) first at : $($first.TimeGenerated) `rTotal events: $($list.count)`rThe last event of eventID $($first.EventID) was found at : $($Last.TimeGenerated)`rThe last event of eventID $($last.EventID) message body : `r$($Last.Message)"
} else {
  Write-log -message 'No events for the query provided were found'
  Clear-Files
  throw 'No events for the query provided were found'
}
