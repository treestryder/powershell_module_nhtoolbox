function Get-UniqueTcpConnections {
<#
.SYNOPSIS
    Records network connection activity over time. With a built-in installer.
#>
    [CmdletBinding()]
    param (
        [string]$PersistanceFile,
        [int]$SleepSeconds = 0,
        [switch]$RunAtStartup,
        [switch]$RemoveStartup
    )

    if ($RunAtStartup -or $RemoveStartup) {

        $TaskName = 'Get-UniqueTcpConnections'
        $InstallPath = "$env:ProgramFiles"
        $ScriptInstallPath = Join-Path $InstallPath 'Get-UniqueTcpConnections.ps1'

        if ($RunAtStartup) {
            if ([string]::IsNullOrEmpty( $PersistanceFile )) {
                $PersistanceFile = "$env:windir\Logs\UniqueTcpConnections.csv"
            }

            if ($SleepSeconds -le 0) {
                $SleepSeconds = 30
            }

            if ( !($PSScriptRoot)) {
                $PSScriptRoot = split-path $MyInvocation.MyCommand.Path -Parent
            }

            if ((Test-Path $InstallPath) -ne $true) {
                New-Item -Path $InstallPath -ItemType Directory | Out-Null
            }

            Get-Command Get-UniqueTcpConnections |
             Select-Object -ExpandProperty Definition |
              Set-Content -Path $ScriptInstallPath

            Write-Verbose "Scheduling task."
            $task = 'Powershell.exe -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File \"{0}\" \"{1}\" {2}' -f $ScriptInstallPath, $PersistanceFile, $SleepSeconds
            SCHTASKS /CREATE /TN $TaskName /TR $task /SC ONSTART /RU SYSTEM /F
            SCHTASKS /RUN /TN $TaskName
            return
        }
        else {
            SCHTASKS /END /TN $TaskName
            SCHTASKS /DELETE /TN $TaskName /F
            Remove-Item -Path $ScriptInstallPath
            return
        }

    }

    #$NetstatRegex = '^.{9}(?<localIp>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\:(?<localPort>\d+)\s+(?<remoteIp>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\:(?<remotePort>\d+)'
    $NetstatRegex = '^.{8}\s(?<localIp>[a-f\d][a-f\d\.:]+):(?<LocalPort>\d+)\s+(?<RemoteIp>[a-f\d][a-f\d\.:]+):(?<remotePort>\d+)\s'
    $ConnectionTemplate = 0 | select LocalIp, LocalPort, RemoteIp, RemotePort, LastSeen

    $latest = @{}
    function UpdateLatestConnection ([PSCustomObject]$Connection) {
        $key = '{0}#{1}#{2}#{3}' -f $Connection.RemoteIp, $Connection.RemotePort, $Connection.LocalIp, $Connection.LocalPort
        if ($latest.ContainsKey($key) -and $latest[$key].LastSeen -ge $Connection.LastSeen) { return }
        $latest[$key] = $Connection
    }

    if ([string]::IsNullOrEmpty( $PersistanceFile ) -ne $true -and (Test-Path $PersistanceFile)) {
        Import-Csv $PersistanceFile | foreach {
            UpdateLatestConnection $_
        }
    }

    do {
        $now = Get-Date

        # Using Netstat, as the following only works on Server 2012 and newer
        #  Get-CimInstance -ClassName MSFT_NetTCPConnection -Namespace ROOT/StandardCimv2

        netstat -n | foreach {
            if ($_ -match $NetstatRegex) {
                $connection = $ConnectionTemplate.psobject.Copy()
                $connection.LocalIp    = $Matches['LocalIp']
                $connection.LocalPort  = $Matches['LocalPort']
                $connection.RemoteIp   = $Matches['RemoteIp']
                $connection.RemotePort = $Matches['RemotePort']                                                                                                                                                                                                                 
                $connection.LastSeen   = $now

                UpdateLatestConnection $connection
            }
        }

        if ([string]::IsNullOrEmpty( $PersistanceFile ) -ne $true) {
            $latest.Values | Export-Csv -NoTypeInformation $PersistanceFile
        }
        else {
            $latest.Values
        }

        if ($SleepSeconds -gt 0) {
            Start-Sleep $SleepSeconds
        }

    } while ($SleepSeconds -gt 0)
}