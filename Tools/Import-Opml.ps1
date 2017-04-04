function Import-Opml {
<#
.Synopsis
Imports an OPML file into Powershell custom objects.

#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        [object[]]$Path
    )
 
    begin {
        $outputTemplate = [pscustomobject][ordered]@{
            Type=$null
            Name=$null
            Uri=$null
        }
    }
    
    process {
        foreach ($p in $Path) {
            $xml = [xml](Get-Content -Path $p -Raw)
            
            foreach ($outline in $xml.opml.body.outline.outline) {
                $o = $outputTemplate.psobject.Copy()
                $o.Type = $outline.type
                $o.Name = $outline.text
                $o.Uri = $outline.xmlUrl
                Write-Output $o
            }
        }
    }
}
