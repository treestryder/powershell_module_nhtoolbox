function Set-NicSettings {
    <#
    .Synopsis
        Sets network card settings.

    .DESCRIPTION
        Sets network card settings. By default it only turns off NetBIOS and WINS.
        Can also set DNS and Domain Suffix Search Order.

    .EXAMPLE
        Set-NICSettings -Computer 'computer1', 'computer2'
        Turn off NetBIOS and WINS on computer1 and computer2

    .EXAMPLE
        Get-Content ServerFile.txt | Set-NICSettings -DNSServers '192.168.1.1', '192.168.2.1'
        Turns off NetBIOS and WINS, plus sets DNS Server settings on a list of
        computer names found in ServerFile.txt.

    .EXAMPLE
        Import-Csv ServerFile.csv | Set-NICSettings -DNSServers '192.168.1.100', '192.168.2.100', '192.168.3.100'
        Same as the example above, except that it shows you can pull the values
        from a CSV file (or object) that has a ComputerName column.
       
    #>
    [CmdletBinding()]
    param (
        [Alias('DNSHostName', 'HostName', 'Name')]
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [object[]]$ComputerName = '.'
        ,[string[]]$DNSServers
        ,[String[]]$DNSDomainSuffixSearchOrder
        ,[switch]$Force
    )

    Begin {
        $filter = 'IpEnabled=true'
        if ($Force) { $filter = $null }
    }

    Process {
        ForEach ($Computer in $ComputerName) {
            Write-Verbose "Setting NIC settings for $Computer"

            Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer -filter $filter | 
             Where {$Force -or $_.IPAddress -ne '0.0.0.0'}  |
              foreach {
                if ($DNSServers) {$_.SetDNSServerSearchOrder($DNSServers) | Out-Null }
                if ($DNSComainSuffixSearchOrder) { $_.DNSDomainSuffixSearchOrder = $DNSDomainSuffixSearchOrder }
                $_.SetWINSServer('','') | Out-Null
                $_.SetTcpipNetbios(2) | Out-Null
                $_.WINSEnableLMHostsLookup = $false
                # The following does not seem to work as advertised.
                # $_.EnableWINS($true,$false,$null,$null)
              }
        }
    }
}
