<#
.Synopsis
Converts GPX content into Powershell custom objects.

.Example
Import-Csv coordinates.csv | ConvertTo-GpxTrack | Set-Content coordinates.gpx

#>
function ConvertTo-GpxTrack {
  [CmdletBinding()]
  param (
      [Parameter(
          Mandatory=$true,
          ValueFromPipelineByPropertyName=$true
      )]
      [float]
      $Lat,
      [Parameter(
          Mandatory=$true,
          ValueFromPipelineByPropertyName=$true
      )]
      [float]
      $Lon,
      [Parameter(
          ValueFromPipelineByPropertyName=$true
      )]
      [float]
      $Ele,
      [Parameter(
          ValueFromPipelineByPropertyName=$true
      )]
      [DateTime]
      $Time = (Get-Date),
      [Parameter(
          ValueFromPipelineByPropertyName=$true
      )]
      [float]
      $Hdop,
      [Parameter(
          ValueFromPipelineByPropertyName=$true
      )]
      [float]
      $Speed
  )
 
  begin {
@'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<gpx version="1.1" creator="ConvertTo-GpxTrkpt" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
  <trk>
    <trkseg>
'@ | Write-Output
  }

  process {

@'
      <trkpt lat="{0}" lon="{1}">
        <ele>{2}</ele>
        <time>{3:o}</time>
        <hdop>{4}</hdop>
        <extensions>
          <speed>{5}</speed>
        </extensions>
      </trkpt>
'@ -f $Lat, $Lon, $Ele, $Time, $Hdop, $Speed |
  Write-Output

  }


  end {
@'
    </trkseg>
  </trk>
</gpx>
'@ | Write-Output
  }
}