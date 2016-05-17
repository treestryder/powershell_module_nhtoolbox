# Inspiration (initial source) based on the Windows PowerShell Team Blog
function Format-Xml {
<#
.Synopsis
Indents XML or strings of XML.

.Description
Indents XML or strings of XML. Excepts piped input.

.Parameter InputObject
Xml object to be formatted. Other objects are converted to strings, concatenated together,
then cast to an XML object.

.Parameter Indent
The number of spaces to indent the formated XML.

.Example
Get-Content input.xml | Format-Xml | Set-Content output.xml

Reformats the Xml document input.xml and saves it to output.xml.

.Example
$xml = Get-SomeXmlObject

Format-XML $xml -Indent 4 | clip

Retrieves an XML object from an arbitrary function, reformats the XML with a
4 space indent and saves the result to the clipboard.

#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        $InputObject,

        [Parameter(
            Position=1
        )]
        [int]$Indent = 2
    )
 
    begin {
        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = "indented"
        $xmlWriter.Indentation = $Indent

        function do-format {
            param ([xml]$x)
            $x.WriteContentTo($XmlWriter)
            $XmlWriter.Flush()
            $StringWriter.Flush()
            Write-Output $StringWriter.ToString()
        }
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
            do-format $xml
        }
    }
}

