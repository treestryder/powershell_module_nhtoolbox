<#
.Synopsis
   Prevents the screen from locking. 
.DESCRIPTION
   Starts a background Powershell job, which sends the key {F15}, which should
   not be registered, every minute to prevent the screen from locking.
.EXAMPLE
   Suspend-ScreenLock

   Suspends the screen locking indefinately.
.EXAMPLE
   Suspend-ScreenLock -ForMinutes 60

   Suspends the screen locking for an hour.

#>
function Suspend-ScreenLock
{
    [CmdletBinding()]
    Param (
        [int] $ForMinutes,
        [datetime]$Until,
        [switch]$Stop
    )
    if ($Stop) {
        Get-Job -Name StopScreenSaver -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job
        Write-Verbose 'Suspend-ScreenLock Stopped'
        return
    }
    if ($Until -eq $null -and $ForMinutes -gt 0) {
        $Until = (Get-Date).AddMinutes($ForMinutes)
    }
    if ($Until -eq $null) {
        $Until = [datetime]::MaxValue
        Write-Verbose 'Suspend-ScreenLock running indefinately. To stop: Suspend-ScreenLock -Stop'
    } else {
        Write-Verbose "Suspend-ScreenLock running until $Until. To stop: Suspend-ScreenLock -Stop"
    }

    Start-Job -Name StopScreenSaver -ArgumentList $Until -ScriptBlock {
        Param ($Until)
        $ws = New-Object -ComObject 'WScript.Shell'
        while ((Get-Date) -lt $Until) {
            $ws.SendKeys('{F15}')
            Start-Sleep -Seconds (60)
        }
    }
}