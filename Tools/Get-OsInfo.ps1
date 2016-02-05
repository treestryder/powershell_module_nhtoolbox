function Get-OsInfo {
<#
.Synopsis
Gets operating system information for one or more computers.

.Description
Uses WMI to get operating system information for one or more computers.

.Parameter ComputerName
One or more computer names. Excepts piped input.

.Example
LTM\Get-OSInfo -ComputerName SomeComputer

.Example
Get-Content 'Computers.txt' | LTM\Get-OSInfo

#>
    [CmdletBinding()]
    param(
	    [Parameter(ValueFromPipeline=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = '.'
    )
    
    process {
		foreach ($c in $ComputerName) {
			try {
				# Only works on 2008 or newer: Get-CimInstance -ClassName win32_operatingsystem -ComputerName $ComputerName
				$os = Get-WmiObject -ClassName win32_operatingsystem -ComputerName $ComputerName
				# Convert dates to DateTime objects.
				if ($os) {
                    $os | Add-Member -MemberType AliasProperty -Force -Name ComputerName -Value '__SERVER'
					$os | Add-Member -MemberType NoteProperty -Force -Name InstallDate -Value $(
						if ($os.InstallDate) {$os.ConvertToDateTime($os.InstallDate)}
					)
					$os | Add-Member -MemberType NoteProperty -Force -Name LastBootUpTime -Value $(
						if ($os.LastBootUpTime) {$os.ConvertToDateTime($os.LastBootUpTime)}
					)
					$os | Add-Member -MemberType NoteProperty -Force -Name LocalDateTime -Value $(
						if ($os.LocalDateTime) {$os.ConvertToDateTime($os.LocalDateTime)}
					)
				}
				Write-Output $os
			}
			catch {
				Write-Warning "Unable to access $ComputerName to gather OS info with WMI."
				throw $_
			}
		}
    }
}