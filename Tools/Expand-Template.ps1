function Expand-Template {
<#
.Synopsis
Processes a string as a template.

.Description
Uses the .Net format syntax, after first converting any matching keys in a hash table or properties in an object to their respective index value.

.Example
Expand-Template -Value @{a=1} -Template 'a = {a}'
 a = 1


.Example

Expand-Template -Template 'Y2K happened on {day:dddd}' -Value @{ day = (Get-Date '1/1/2000') }

Y2K happened on Saturday


.Example

Expand-Template -Template ' {decimal:0.0#} {stringName,20} ' -Value @{ stringName = 'stringValue'; miss = 'test'; decimal = 123.456 }

 08/05/2016 stringValue

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Hashtable')]
        [hashtable[]]$Hashtable,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='PSObject')]
        [PSObject[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [string]$Template
    )
    
    begin {
        function ProcessHashtable {
            param (
                [hashtable]$Hashtable,
                [string]$Template
            )
            $i = 0
            foreach ($key in $Hashtable.Keys) {
                $TokenRegex = "\{$key(\}|[\,\:][^\}]+\})"
                $Template = $Template -replace $TokenRegex, "{$i`$1"
                $i++
                Write-Verbose "Regex:    $TokenRegex"
                Write-Verbose "Template: $Template"
            }
            return $Template -f [array]$Hashtable.Values
        }
    }

    process {
        foreach ($h in $Hashtable) {
            ProcessHashtable -Hashtable $h -Template $Template
        } 

        foreach ($o in $InputObject) {
            $ht = @{}
            $o.psobject.Properties | foreach {
                $ht.Add($_.Name,$_.Value)
            }
            ProcessHashtable -Hashtable $ht -Template $Template -verbose
        }
    }
}
