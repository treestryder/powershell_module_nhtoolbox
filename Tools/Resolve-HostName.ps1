<#
.Synopsis
Resolves IP addresses and Hostnames, like NSLookup.

.Description
Returns HostName given an IP address and an IP address given a HostName.

.Parameter $ComputerName
Host Name or IP Address to be resolved.

.Parameter Expand
Expands the returned Alias and AddressList Arrays to a single string each.

#>
function Resolve-HostName {
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [alias('CN','MachineName','Name','Host','IP','HostName','DnsHostName','PSComputerName','CSName','__Server')]
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [switch]$Expand
    )
    process {
        Foreach ($c in $ComputerName) {
			Write-Verbose $c
		    try {
			    $result = [System.Net.Dns]::GetHostEntry($c)
                if ($Expand) {
					$o = [PSCustomObject][ordered]@{
						HostName = $result.HostName
						Aliases = $result.Aliases -join ', '
						AddressList = $result.AddressList -join ', '
					}
					Write-Output $o
				} else {
					Write-Output $result
				}
		    }
		    catch {
				Write-Error $_
		    }
        }
    }
}
