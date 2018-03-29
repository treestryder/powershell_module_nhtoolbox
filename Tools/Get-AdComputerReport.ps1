function Get-AdComputerReport {
    <#
    .Synopsis

    Creates a simple Active Directory computer report using AD and quering the machines with WMI.

    .Notes
    Requires Microsoft's ActiveDirectory module and WMI access to each machine.

    #>
    param (
        # A valid Get-AdComputer Filter.
        [string]$Filter = $('name -eq "{0}"' -f $env:COMPUTERNAME)
    )

    #Requires -Module ActiveDirectory

    $outputTemplate = [pscustomobject][ordered] @{
        Name = $null
        DNSHostName = $null
        CanonicalName = $null
        DistinguishedName = $null
        Location = $null
        OperatingSystem = $null
        Created = $null
        Modified = $null
        Enabled = $null
        IP = $null
        Pingable = $null
        NameMatchesAUsername = $null
        Description = $null
        Caption = $null
        CSDVersion = $null
        Version = $null
        SerialNumber = $null
        ProductType = $null
    }

    $adProperties = 'Name',
                'DNSHostName',
                'CanonicalName',
                'DistinguishedName',
                'Location',
                'OperatingSystem',
                'Created',
                'Modified',
                'Enabled'

    Get-ADComputer -Filter $filter -ResultSetSize $null -Properties $adProperties |
        Foreach {
            $ComputerName = $_.DNSHostName, $_.Name, 'No Name in AD' | where {$_ -ne $null} | select -First 1

            $o = $outputTemplate.psobject.Copy()
            foreach ($p in $adProperties) {
                $o.$p = $_.$p
            }
            $o.NameMatchesAUsername = try { (Get-ADUser -Identity $_.Name) -ne $null } catch {$false}
            $o.IP = try { (Resolve-HostName $ComputerName).AddressList} catch {}
            $o.Pingable = Test-Connection $ComputerName -Quiet -Count 1

            if ($o.Pingable) {
                $wmiOs = try {Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction SilentlyContinue} catch {}
                if ($WmiOs -ne $null) {
                    $o.Description = $wmiOs.Description
                    $o.Caption = $wmiOs.Caption
                    $o.CSDVersion = $wmiOs.CDSVersion
                    $o.Version = $wmiOs.Version
                    $o.SerialNumber = $wmiOs.SerialNumber
                    $o.ProductType = switch ($wmiOs.ProductType) {
                        1 {'Workstation'}
                        2 {'Domain Controler'}
                        3 {'Server'}
                        default {'Unknown'}
                    }
                }
            }
            Write-Output $o
        }
}
