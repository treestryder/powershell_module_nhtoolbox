<#
    .SYNOPSIS Finds Internet Explorer and Edge Favorites in their standard locations using the C$ administrative share.

    .EXAMPLE
    $TisComputers = Get-ADComputer -Filter 'Enabled -eq $true' -SearchBase 'OU=Workstations,OU=TIS-Supported,DC=peckham,DC=org' | Select-Object -ExpandProperty Name
    $TisComputers | Find-Favorites -Verbose | Export-Csv -NoTypeInformation C:\Users\admin.nhartley\Desktop\Favorites-TIS.csv
    
    $BsitComputers = Get-ADComputer -Filter 'Enabled -eq $true' -SearchBase 'OU=Workstations,OU=BSIT-Supported,DC=peckham,DC=org' | Select-Object -ExpandProperty Name
    $BsitComputers | Find-Favorites -Verbose | Export-Csv -NoTypeInformation C:\Users\admin.nhartley\Desktop\Favorites-BSIT.csv

    .NOTES
    Output Properties: URL, ComputerName, FileName, FilePath
#>
function Find-Favorites {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName = $env:COMPUTERNAME
    )

    begin {

        $folders =
            '\\{0}\C$\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\*',
            '\\{0}\C$\Users\*\Favorites\*',
            '\\{0}\C$\Users\*\Desktop\*',
            '\\{0}\C$\ProgramData\Microsoft\Windows\Start Menu\*'

        $OutputTemplate = [psCustomObject][Ordered]@{
            Name = $null
            URL = $null
            ComputerName = $null
            FilePath = $null
        }


        function GetUrl ($Path) {
            Get-Content -Path $Path |
                ForEach-Object {
                    if ($_ -match '^URL=(.+)$') {
                        Write-Output $Matches[1]
                    }
                }
        }

    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose $ComputerName
            foreach ($folder in $folders) {
                $path = $folder -f $computer
                Write-Verbose "    $path"
                Get-ChildItem -Path $path -Recurse -Include *.url,*.website -ErrorAction SilentlyContinue |
                    Foreach {
                        Write-Verbose "        $($_.FullName)"
                        $output = $OutputTemplate.psobject.Copy()
                        $output.Name = $_.BaseName
                        $output.URL = GetUrl -Path $_.FullName
                        $output.Computername = $computer
                        $output.FilePath = $_.FullName
                        $output | Write-Output
                    }
            }
        }
    }
}
