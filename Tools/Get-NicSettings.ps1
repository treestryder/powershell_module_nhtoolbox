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
            #ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [object[]]$ComputerName = '.',
        [switch]$Force
    )

    Begin {
        $filter = 'IpEnabled=true'
        if ($Force) { $filter = $null }
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
                WINSEnableLMHostsLookup,TcpipNetbiosOptions,WINSPrimaryServer,WINSSecondaryServer
        }
    }
}

