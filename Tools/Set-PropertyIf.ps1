function Set-PropertyIf {
<#
.Synopsis
A simple decision engine that sets property values based on a filter matrix.

.Description
A simple decision engine that sets property values based on a filter matrix.
Primarily designed to process CSV files, based on rules stored in a csv file, this
function can process any objects, both as input or rules. Unless overridden by a
rule, input objects will pass through unaltered.Rules have two components; one
or more "If"s and one or more "Set"s. The "If"s are specified by prepending "If_"
to the property name that will be compared to the input. The "Set"s have the same
name as the input object property names. By default the rule comparisons use the
Powershell -Like operator. Regular expressions can be used by specifying the -Regex
parameter. The special "Set" value "^^^" (for use the above value) can be specified
to prevent overwriting a value on a match. 

.Parameter InputObject
Any object with properties, that will cast to a PSCustomObject. Allows piped input. 

.Parameter Rule
Rules have two components; one or more "If"s and one or more "Set"s. The "If"s are
specified by prepending "If_" to the property name that will be compared to the
input. The "Set"s have the same name as the input object property names. By default
the rule comparisons use the Powershell -Like operator. Regular expressions can be
used by specifying the -Regex parameter. The special "Set" value "^^^" (for use
the above value) can be specified to prevent overwriting a value on a match.

.Parameter IdProperty
Optional input object ID property for Verbose logging. Defaults to "ID".

.Parameter RuleIdProperty
Optional Rule ID property for Verbose logging. Defaults to "RuleId".

.Parameter AllMatches
This paramter causes all matches to be processed. All Set properties will be
overwritten, unless the special value "^^^" is specified. Defaults to stopping
on the first match.

.Paramter Regex
Uses Regular Expressions for matching If properties. Defaults to using the
Powershell -Like comparison.

 .Inputs
 System.Management.Automation.PSObject other objects will be cast to PSObjects.

 .Outputs
 System.Management.Automation.PSObject

.Example
$Rule = ConvertFrom-Csv @'
RuleID,If_PropertyA,PropertyB,NewPropertyC
Rule1,*,^^^,Default Rule. Does not change Property B.
Rule2,PA1*,^^^,Matched 2 Entries and one is overridden by next rule. Does not change Property B.
Rule3,PA1a,PB Changed,Changes Property B on one of the earlier matched entries.
'@

$Data = ConvertFrom-Csv @'
ID,PropertyA,PropertyB
Record1,PA1a,PB
Record2,PA1b,PB
Record3,PA2,PB
'@

$Data | Set-PropertyIf -Rules $Rule -Verbose -AllMatches

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline=$true,
                   Position=0
        )]
        [pscustomobject]$InputObject,
        
        [Parameter(Mandatory = $true,
                   Position=1
        )]
        [ValidateNotNullOrEmpty()]
        [pscustomobject[]]$Rule,
        [string]$IdProperty = 'ID',
        [string]$RuleIdProperty = 'RuleID',
        [switch]$AllMatches,
        [switch]$Regex
    )

    begin {
        [string[]]$AllProperties = $Rule[0].psobject.Properties.Name
        [string[]]$SetProperties = $AllProperties | where {$_ -notmatch '^If_'}
        [string[]]$Ifs = $AllProperties | where {$_ -match '^If_' }
        #[string[]]$SelectProperties = @('*') + $SetProperties
        
        Write-Verbose ('If Properties: {0}' -f ($Ifs -join ', '))
        Write-Verbose ('Set Properties: {0}' -f ($SetProperties -join ', '))
    }


    process {
        foreach ($in in $InputObject) {
            $SelectProperties = @($in.psobject.Properties.Name) + $SetProperties | select -Unique
            $out = $in | select $SelectProperties
            
            $hasRuleHit = $false
            foreach ($r in $Rule) {
                $isAlike = $true
                foreach ($if in $Ifs) {
                    $ifColumn = $if.substring(3)
                    if (
                        ($Regex -and $in."$ifColumn" -notmatch $r."$if") -or 
                        $in."$ifColumn" -notlike $r."$if"
                    ) {
                        $isAlike = $false
                        break # out of comparing Ifs
                    }
                }
                if ($isAlike) {
                    $hasRuleHit = $true
                    if ($out.psobject.Properties.Name-contains $IdProperty -and $out.psobject.Properties.Name -contains $RuleIdProperty) {
                        Write-Verbose "Input ID [$($out."$IdProperty")] matched rule ID [$($rule."$RuleIdProperty")]."
                    }
                    foreach ($setProperty in $SetProperties) {
                        # Unless the rule's set property is '^^^', set the value in the output to that in the rule.
                        if ($r."$setProperty" -notmatch '^\s*\^\^\^\s*$') {
                            $out."$setProperty" = $r."$setProperty"
                        }
                    }
                }
                if ($AllMatches -eq $false -and $hasRuleHit) {
                    break # out of rule checking
                }
            }
            Write-Output $out
        } # end foreach input object
    } # end process
} # end function
