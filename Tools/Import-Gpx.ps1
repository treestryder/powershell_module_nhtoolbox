# Inspiration (initial source) based on the Windows PowerShell Team Blog
function Import-Gpx {
<#
.Synopsis
Imports GPX file.

.Parameter InputObject
Xml object to be formatted. Other objects are converted to strings, concatenated together,
then cast to an XML object.

.Example
Get-Content input.gpx | Import-Gpx

Imports the data contained in input.gpx.

#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        $InputObject
    )
 
    begin {
        $stringCache = New-Object System.Text.StringBuilder
    }
    
    process {
        foreach ($input in $InputObject) {
            if ($input -is [xml]) {
                do-format $input
            }
            elseif ($input -is [string]) {
                $null = $stringCache.Append($input)
            }
            elseif ($input -ne $null) {
                $null = $stringCache.Append($input.ToString())
            }
        }
    }

    end {
        if ($stringCache.Length -gt 6) {
            $xml = [xml]$stringCache.ToString()
            $xml.gpx.wpt |
             Add-Member -MemberType ScriptProperty -PassThru -Name 'OsmUri' -Value {
                 'http://www.openstreetmap.org/?mlat={0}&mlon={1}' -f $this.lat, $this.lon
             } |
              Add-Member -MemberType ScriptProperty -PassThru -Name 'GoogleUri' -Value {
                 'https://www.google.com/maps/@{0},{1}' -f $this.lat, $this.lon
              }
        }
    }
}
gc C:\Users\natha\Downloads\favourites.gpx | Import-Gpx 
