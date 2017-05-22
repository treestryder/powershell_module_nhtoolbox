
<#
.SYNOPSIS
    Ensures that at least one of a list of Hotfixes have been installed on one or more computers.

.EXAMPLE
    # This example scans a single compture for a single Hotfix.

    Assert-HotfixInstalled -ComputerName somePc -Id KB1234567

.EXAMPLE
    # This example retrieves a list of enabled computers from Active Directory and
    # scans them for a list of Hotfixes, writing the results to a dated log file.

    $Computers = Get-ADComputer -Filter '*' | where {$_.enabled} | select -ExpandProperty Name

    $KBs = 'KB4012212','KB4012213','KB4012214','KB4012215','KB4012216','KB4012217','KB4012598','KB4012606','KB4013198','KB4013429'

    $Log = '.\AssertHotfixInstalled_{0:yyyyMMddhh}.csv' -f (Get-Date)
    Write-Host $Log
    $Computers | Assert-HotfixInstalled -Id $KBs | Export-Csv -NoTypeInformation $Log

#>

class AssertKbInstalledResult {
    [string]$ComputerName
    [System.Nullable``1[[System.Boolean]]]$KbInstalled
    [string]$Message
    [string]$Description
    [string]$Caption
    [string]$Version
    [string]$BuildNumber
    [string]$OSArchitecture
    [System.Nullable``1[[System.DateTime]]]$LastBootUpTime
}

function Assert-HotfixInstalled {
    [CmdletBinding()]
    [OutputType([AssertKbInstalledResult])]

    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Name','CN')]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,
        [string[]]
        $Id
    )

    process {
        foreach ($c in $ComputerName) {
            $o = New-Object AssertKbInstalledResult
            $o.ComputerName = $c
            if (Test-Connection -ComputerName $c -Count 1 -Quiet) {
                try {
                    $os = Get-WmiObject -ClassName win32_operatingsystem -ComputerName $c -ErrorAction Stop
                    $o.Description = $os.Description
                    $o.Caption = $os.Caption
                    $o.Version = $os.Version
                    $o.BuildNumber = $os.BuildNumber
                    $o.OSArchitecture = $os.OSArchitecture
                    $o.LastBootUpTime = try {$os.ConvertToDateTime($os.LastBootUpTime)} catch {}
                    # Throws an exception, when the Hotfixes are not found.
                    $hf = @(Get-HotFix -Id $Id -ComputerName $c -ErrorAction Stop)
                    $hotFixes = $hf | foreach { '{0} ({1:g})' -f $_.HotFixID, $_.InstalledOn }
                    $o.Message = $hotFixes -join ', '
                    $o.KbInstalled = $true
                }
                catch {
                    if ($_.FullyQualifiedErrorId -eq 'GetHotFixNoEntriesFound,Microsoft.PowerShell.Commands.GetHotFixCommand') {
                        $o.KbInstalled = $false
                    }
                    else {
                        $o.Message = "Error: $_"
                    }
                }
            }
            else {
                $o.Message = 'Unpingable'
            }
            Write-Output $o
        }
    }
}
