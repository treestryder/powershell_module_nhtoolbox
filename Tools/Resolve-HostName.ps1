function Resolve-HostName {
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [alias('CN','MachineName','Name','Host','IP','HostName')]
        [String[]]$ComputerName,
        [switch]$Expand
    )
    process {
        Foreach ($c in $ComputerName) {
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
			    Write-Warning "Lookup of [$c] failed."
				throw $_
		    }
        }
    }
}