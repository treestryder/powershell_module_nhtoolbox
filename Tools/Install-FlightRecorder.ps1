function Install-FlightRecorder {
    <#
    .SYNOPSIS
    Installs or sets up the pieces necessary to create PerfMon Collector 
    snapshots, one a minute, to a file located in C:\FlightRecorder.

    .DESCRIPTION
    Installs or sets up the pieces necessary to create PerfMon Collector 
    snapshots, one a minute, to a file located in C:\FlightRecorder.

    .PARAMETER Path
    File listing performance counters to collect, one per line. 
    Or a PAL Threshold XML file.

    .NOTES
    Must be ran as an admininstrator.
    
    #>
    [CmdletBinding()]
    param (
        [string]$Path
    )

    # #Requires -RunAsAdministrator
    $DeleteTempFile = $False

    function Main {
        if (-not $Path) { $Path = DefaultFile $Path }
        if (-not (Test-Path $Path)) {
            Write-Warning "Path does not exist or is inaccessable: $Path"
            Exit 1
        }
        if ($Path -like '*.xml') { $Path = PALFile $Path }

        InstallFlightRecorder
        if ($Path.startswith($env:TEMP)) {Remove-Item $Path}
        Write-Verbose 'Installation Successful.'
    }

    function InstallFlightRecorder {
        Write-Verbose 'Setting up the Flight Recorder.'
        if (-not (Test-Path c:\FlightRecorder\)) {
            mkdir c:\FlightRecorder | out-null 
        }
        if ((LOGMAN query) -match 'FlightRecorder') {
            Write-Verbose 'Removing former FlightRecorder PerfMon Collector.'
            LOGMAN stop FlightRecorder | out-null
            LOGMAN delete FlightRecorder | Write-Verbose
        }
        Write-Verbose 'Creating FlightRecorder PerfMon Collector.'
        LOGMAN create counter FlightRecorder -o "C:\FlightRecorder\FlightRecorder_$env:computername" -cf $Path -v mmddhhmm -si 00:01:00 -f bin | Write-Verbose
        SCHTASKS /Create /TN FlightRecorder-Nightly /F /SC DAILY /ST 00:00 /RU SYSTEM /TR 'powershell.exe -command LOGMAN stop FlightRecorder; LOGMAN start FlightRecorder; dir c:\FlightRecorder\*.blg |?{ $_.LastWriteTime -lt (Get-Date).AddDays(-3)} | del' | Write-Verbose
        SCHTASKS /Create /TN FlightRecorder-Startup /F /SC ONSTART /RU SYSTEM /TR "LOGMAN start FlightRecorder" | Write-Verbose
        SCHTASKS /Run /TN FlightRecorder-Startup | Write-Verbose
    }

    function DefaultFile {
        Write-Warning 'Counter or PAL file not specified, using default configuration.'
        $DeleteTempFile = $True
        $Path = [System.IO.Path]::GetTempFileName()
        Set-Content -Encoding ASCII $Path @'
\LogicalDisk(*)\Avg. Disk sec/Read
\LogicalDisk(*)\Avg. Disk sec/Write
\LogicalDisk(*)\Disk Transfers/sec
\LogicalDisk(C:)\Free Megabytes
\Memory\% Committed Bytes In Use
\Memory\Available MBytes
\Memory\Committed Bytes
\Memory\Free System Page Table Entries
\Memory\Pages Input/sec
\Memory\Pages/sec
\Memory\Pool Nonpaged Bytes
\Memory\Pool Paged Bytes
\Memory\System Cache Resident Bytes
\Network Interface(*)\Bytes Total/sec
\Network Interface(*)\Output Queue Length
\Paging File(*)\% Usage
\Paging File(*)\% Usage Peak
\PhysicalDisk(*)\Avg. Disk sec/Read
\PhysicalDisk(*)\Avg. Disk sec/Write
\Process(_Total)\Handle Count
\Process(_Total)\Private Bytes
\Process(_Total)\Thread Count
\Process(_Total)\Working Set
\Processor(*)\% Interrupt Time
\Processor(*)\% Privileged Time
\Processor(*)\% Processor Time
\System\Context Switches/sec
\System\Processor Queue Length
'@
        Write-Output $Path
    }

    function PalFile {
        $DeleteTempFile = $True
        $InputPath = $Path
        $Path = [System.IO.Path]::GetTempFileName()
        $filesRead = @()
        Read-PalFile $InputPath | Select -Unique | sort | Set-Content -Encoding ASCII $Path
        $Path
    }

    $script:filesRead =@()
    function Read-PalFile ([string]$path) {
        if (-not (Test-Path $path)) {
            Write-Warning "PAL Threshold file not found: $path"
            return
        }
        if ($script:filesRead -contains $path) {return}
        $script:filesRead += @($path)
        Write-Verbose "Reading PAL Threshold file: $path"
        $xml = [XML](Get-Content $path)
        $xml.SelectNodes('//DATASOURCE[@TYPE="CounterLog"]') | select -expand EXPRESSIONPATH
        $xml.SelectNodes('//INHERITANCE/@FILEPATH') | select -expand '#text' | where {$_ } | ForEach {
            $newpath = Join-Path (Split-Path -parent $path) $_
            Write-Debug "Inheritance file: $newpath"
            Read-PalFile $newpath
        }
    }

    . Main
}