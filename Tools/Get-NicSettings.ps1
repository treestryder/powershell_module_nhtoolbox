function Get-NicSettings {
    <#
    .Synopsis
       Retreives specific network settings. Initially created to facility a domain merger.

    .EXAMPLE
        Get-NicSettings

        Retrieves local NIC information.

    .EXAMPLE
        $AllComputersInAd = Get-ADComputer -ResultSetSize $null -Filter * | Select -ExpandProperty DNSHostName
        $PingableComputers = $AllComputersInAd | where {Test-Connection -ComputerName $_ -Quiet -Count 1}
        $PingableComputers | Get-NicSettings -Verbose -Force | Export-Csv -NoTypeInformation NIC_Settings.csv

        Exports, to a CSV file, all NIC settings from every computer listed in AD.
    #>
    
    [CmdletBinding()]
    param (
        [Alias('DNSHostName', 'HostName', 'Name')]
        [Parameter(
			Position=0,
            ValueFromPipelineByPropertyName=$true
        )]
        [object[]]$ComputerName = '.',
        [switch]$Force
    )

    Begin {
        $filter = 'IpEnabled=true'
        if ($Force) { $filter = $null }
		# Bitmap of the possible settings related to NetBIOS over TCP/IP. Values are identified in the following table.
		$TcpipNetbiosOptions = 'EnableNetbiosViaDhcp (0)', 'EnableNetbios (1)', 'DisableNetbios (2)'
    }

    Process {
        ForEach ($Computer in $ComputerName) {
            Write-Verbose "Gathering NIC settings for $Computer"

            Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer -filter $filter | 
             Where {$Force -or $_.IPAddress -ne '0.0.0.0'}  |
              Select-Object DNSHostName,Description,MACAddress,DNSDomain,DHCPEnabled,
                @{Name='IPAddress';Expression={$_.IPAddress -join ', '}},
                @{Name='IPSubnet';Expression={$_.IPSubnet -join ', '}},
                @{Name='DefaultIPGateway';Expression={$_.DefaultIPGateway -join ', '}},
                @{Name='DNSServerSearchOrder';Expression={$_.DNSServerSearchOrder -join ', '}},
				@{Name='TcpipNetbiosOptions'; Expression={$TcpipNetbiosOptions[$_.TcpipNetbiosOptions]}},
                WINSEnableLMHostsLookup,WINSPrimaryServer,WINSSecondaryServer
        }
    }
}

