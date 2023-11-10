<#
  .SYNOPSIS
  Saves a log of last Non-idle actions on a computer

  .DESCRIPTION
  This script will determine if a user had moved the mouse or touched a key and tell you how long it has been since this has happened.
  This should be a scheduled - re-ocurring task in the rmm.
  
  .OUTPUTS
  System.String
  C:\ProgramData\ASG\ScriptLogs\Save-ActivityReport.log  

  .EXAMPLE
  PS> .\Save-ActivityReport.ps1 
  Saves the log file to the appropriate container for review

  .NOTES
  This script was developed by
  Chris Calverley 
  on
  November 10, 2023
  For
  ASGCT
#>

[CmdletBinding()]
Param()

If (!($bootstraploaded)){
    Set-ExecutionPolicy Bypass -scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $BaseRepoUrl = (Invoke-webrequest -UseBasicParsing -URI "https://raw.githubusercontent.com/ASGCT/Repo/main/Environment/Bootstrap.ps1").Content
    $scriptblock = [scriptblock]::Create($BaseRepoUrl)
    Invoke-Command -ScriptBlock $scriptblock

}
Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@


for ( $i = 0; $i -lt 10; $i++ ) {
    $Last = [PInvoke.Win32.UserInput]::LastInput
    $Idle = [PInvoke.Win32.UserInput]::IdleTime
    $LastStr = $Last.ToLocalTime().ToString("MM/dd/yyyy hh:mm tt")
    Write-Log -message ("^<-Start Result-^>")
    Write-Log -message ("Test " + $i)
    Write-Log -message ("   Last user keyboard/mouse input: " + $LastStr)
    Write-Log -message ("   Idle for " + $Idle.Days + " days, " + $Idle.Hours + " hours, " + $Idle.Minutes + " minutes, " + $Idle.Seconds + " seconds.")
    Write-Log -message ("^<-End Result-^>")
    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 10)
}
Write-NewEventlog -EventID 7010 -EntryType 'Information' -Message "Sucessfully Ran $($MyInvocation.ScriptName)"
Clear-Files