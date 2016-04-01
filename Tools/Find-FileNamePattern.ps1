function Find-FileNamePattern {
    <#
    .Synopsis
        Searches all shares or drives of a Windows computer for file name patterns.

    .Description
        Written primarily to find files encrypted by ransomeware, this searches all shares or
        drives of a Windows computer for file name patterns, using Get-ChildItem -Include filters.
        By default, it searches the visible shares of the local computer and stops on the first hit.

        Requires the ability to query WMI and access the files; depending on the parameters locally,
        through a share or administative share.

    .Parameter ComputerName
        Computer name or an array of computer names. Defaults to localhost. Also excepts piped input.

    .Parameter Include
        An array of Get-ChildItem -Include filters. For instance, '*.locky', '_HELP_instructions.txt', '_recovery_*.txt'.

    .Parameter AllMatches
        By default this stops scanning a computer at the first hit. Only the single file is returned.
        When this switch is used all matching files are returned.

    .Parameter AllDrives
        By default this scanned visible shares. When this switch is used, all non-mapped drives are scanned, instead of shares.

    .Example 
        .\Find-FileNamePattern.ps1 -ComputerName SomeComputer -Include '*'

        Scans the shares SomeComputer for any file and stops at the first hit.

    .Example
        Get-Content FileWithComputerNames.txt | .\Find-FileNamePattern.ps1 -AllDrives -AllMatches -Include '*.log' | Export-Csv Report.csv

        Scans the drives of computers listed in FileWithComputerNames.txt for any *.log files and exports the results to output Report.csv.

    .Example
        Import-Csv CsvFileContainingAComputerNameHeading.csv | .\Find-FileNamePattern.ps1 -Include '*.locky', '_HELP_instructions.txt', '_recovery_*.txt' -AllMatches -AllDrives -Verbose | Export-Csv -Path Report.csv -NoTypeInformation
    
        Demonstrates supplying the ComputerNames by piping objects with a ComputerName property, looking for all files matching
        various encryption-ware file name patters, on all drives, and writing the results to a report.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Include,
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias("DNSHostName")]
        [string[]]$ComputerName = 'localhost',
        [switch]$AllMatches,
        [switch]$AllDrives
        )

    begin {
        $ResultTemplate = [pscustomobject][ordered]@{
            ComputerName = $null
            Status = 'ERROR: Unknown Reason.'
            Path = $null
            LastWriteTime = $null
            Length = $null
            Owner = $null
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            $result = $ResultTemplate.psobject.Copy()
            $result.ComputerName = $computer
            if ($computer -eq 'localhost') {
                $result.ComputerName = $env:COMPUTERNAME
            }

            $scopeText = 'first match'
            if ($AllMatches) { $scopeText = 'all matches' }

            $locationText = 'visable shares'
            if ($AllDrives) { $locationText = 'drives' }

            Write-Verbose "Searching $locationText on $($result.ComputerName) for $scopeText of $($Include -join ', ') ..."

            $result.LastWriteTime = Get-Date
            if (-not (Test-Connection -Count 1 -Quiet $Computer)) {
                $result.Status = 'ERROR: Unpingable.'
                $result.LastWriteTime = Get-Date
                Write-Warning "$Computer Unpingable."
                Write-Output $result
                Continue
            }
            try {
                $drives = Get-WmiObject win32_logicaldisk -filter "(drivetype=2 or drivetype=3 or drivetype=5 or drivetype=6) and size > 1" -ComputerName $Computer -ErrorAction Stop | select -ExpandProperty DeviceID
                $shares = Get-WmiObject -ComputerName $Computer -Class Win32_Share -ErrorAction Stop | where {$_.Name -notmatch '\$$'}
            }
            catch {
                $result.Status = 'ERROR: Unable to access WMI: ' + $_.ToString()
                $result.LastWriteTime = Get-Date
                Write-Warning "$Computer Unable to access WMI."
                Write-Output $result
                Continue
            }

            $paths = @()
            if ($AllDrives) {
                foreach ($drive in $drives) {
                    if ($computer -eq 'localhost') {
                        $paths += '{0}\' -f $drive
                    }
                    else {
                        $path += '\\{0}\{1}' -f $Computer, $drive.Replace(':','$')
                    }
                }
            }
            else {
                foreach ($share in $shares) {
                    if ($computer -eq 'localhost') {
                        $paths += $share.Path
                    }
                    else {
                        $path += '\\{0}\{1}' -f $Computer, $share.Name
                    }
                }
            }

            foreach ($path in $paths) {
                Write-Verbose "    Recursively searching $path"
                $clean = $true
                Get-ChildItem -Path (Join-Path $path '*') -Recurse -Include $Include -Verbose:$Verbose -ErrorAction SilentlyContinue -ErrorVariable e | foreach {
                    $clean = $false
                    $result.Status = 'FOUND'
                    $result.Path = $_.FullName
                    $result.Length = $_.Length
                    $result.LastWriteTime = $_.LastWriteTime
                    $result.Owner = (Get-Acl $_.fullname).Owner
                    Write-Verbose "    Found: $($_.FullName)"
                    Write-Output $result
                    if ($AllMatches -eq $false) { Continue }
                }
                $e | foreach {
                    $result.Status = 'ERROR: Accessing: {0} Received: {1}' -f $_.TargetObject, $_.ToString()
                    $result.LastWriteTime = Get-Date
                    Write-Warning $result.Status
                    Write-Output $result
                }
                if ($clean) {
                    $result.Status = 'NOT FOUND'
                    $result.Path = $path
                    $result.LastWriteTime = Get-Date
                    Write-Verbose "    $($Include -join ', ') not found in $($result.Path)"
                    Write-Output $result
                }
            }
        }
    }
}
