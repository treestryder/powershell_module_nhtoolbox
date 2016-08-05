function Expand-Template {
<#
.Synopsis
Processes a string as a template.

.Description
Uses the .Net format syntax, after first converting any matching keys in a hash table to their respective index value.

.Example

Expand-Template -Template 'Y2K happened on {day:dddd}' -Value @{ day = (Get-Date '1/1/2000') }

Y2K happened on Saturday



.Example

Expand-Template -Template ' {dateName:MM/dd/yyyy} {stringName} ' -Value @{ stringName = 'stringValue'; miss = 'test'; dateName = (Get-Date) }

 08/05/2016 stringValue

.Notes
TODO: Handle piped Value input, including objects.

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Value,
        [Parameter(Mandatory=$true)]
        [string]$Template
    )
    $i = 0
    foreach ($key in $Value.Keys) {
        $TokenRegex = "\{$key(\}|\:[^\}]+\})"
        $Template = $Template -replace $TokenRegex, "{$i`$1"
        $i++
        Write-Verbose "Regex:    $TokenRegex"
        Write-Verbose "Template: $Template"
    }
    $Template -f [array]$Value.Values
}
