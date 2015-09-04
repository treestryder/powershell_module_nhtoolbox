#
# NHRegex.psm1
#

function ConvertFrom-Regex {
<#
 .Synopsis
 Converts a string array into a custom PSObject using a Regular Expression as a template.

 .Description
 Converts a string array into a custom PSObjects using a Regular 
 Expression as a template. Capture groups become properties of the 
 PSObjent. Named groups retain their name, unnamed groups get 
 assigned a number beginning at 1.

 .Parameter Pattern
 Regular Expression used to parse the InputObject string.

 .Parameter InputObject
 The string to be parsed. You can pipe the strings to ConvertFrom-Regex.

 .Parameter CaseSensitive
 Performs a case sensitive match.
 
 .Parameter NotMatch
 Return strings that do not match the regular expression.

 .Inputs
 Strings, string arrays otherwise the ToString() method is called on other objects.

 .Outputs
 System.Management.Automation.PSObject

 .Example
 Get-Content SomeFile.txt | ConvertFrom-RegEx '^(?<beginning>.{5})(?<remaining>.*)$'

 .Notes
 TODO: Handle multiple matches in the same line.

#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$True)]
		[string]$Pattern,
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True
		)]
		$InputObject,
		[switch]$CaseSensitive,
        [switch]$NotMatch
	)
	
	begin {
		$RegExOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled
		if (-not $CaseSensitive) { $RegExOptions = $RegExOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
		$RegExObj = New-Object -TypeName System.Text.RegularExpressions.Regex -ArgumentList $Pattern, $RegExOptions
		Write-Verbose "Pattern: $RegExObj"
	}
	
	process {
		$Matches = $RegExObj.Matches($InputObject)
		if (-not $Matches.Success) {
            if ($NotMatch) { return $InputObject }
			Write-Verbose "[$InputObject] did not match."
			return 
		}
		$o = New-Object -TypeName PSCustomObject
		for ($i = 1; $i -lt $Matches.Groups.count; $i++) {
            if ($RegExObj.GroupNameFromNumber($i)) {
			    $o | Add-Member -MemberType NoteProperty -Name $RegExObj.GroupNameFromNumber($i) -Value $Matches.Groups[$i].Value
            }
		}
		$o
	}
}


function Import-Regex {
<#
 .Synopsis
 Converts strings contained in one or more files into a custom PSObjects 
 using a Regular Expression as a template.

 .Description
 Converts a string array into a custom PSObject using a Regular Expression as a template.
 Capture groups become properties of the PSObjent. Named groups retain their name, unnamed
 groups get assigned a number beginning at 1.

 All parameters are passed to Get-Content.

 .Parameter Pattern
 Regular Expression used to parse the InputObject string.

 .Parameter Path
 Specifies the path to an item. Get-Content gets the content of the item.
 Wildcards are permitted. Paths may be piped to Import-RegEx.

 .Parameter CaseSensitive
 Performs a case sensitive match.
 
 .Parameter NotMatch
 Return strings that do not match the regular expression.

 .Inputs
    System.Int64, System.String[], System.Management.Automation.PSCredential
    You can pipe the read count, total count, paths, or credentials to Get-Content.

 .Outputs
 System.Management.Automation.PSObject

 .Example
 Import-RegEx '^(?<beginning>.{5})(?<remaining>.*)$' SomeFile.txt

 .Example
 Get-ChildItem *.txt | Import-RegEx '(?<email>\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)'
 Lists email addresses found in files with a .txt extension. Only the first address will be found.

#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$True)]
		[string]$Pattern,
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True
		)]
		[string[]]$Path,
		[switch]$CaseSensitive,
        [switch]$NotMatch
	)
	
	begin {
		$PSBoundParameters.Remove( 'Pattern' ) | Out-Null
		$PSBoundParameters.Remove( 'CaseSensitive' ) | Out-Null
        $PSBoundParameters.Remove( 'NotMatch' ) | Out-Null
	}
	
	process {
		Get-Content @PSBoundParameters | ConvertFrom-RegEx -Pattern:$Pattern -CaseSensitive:$CaseSensitive -NotMatch:$NotMatch
	}
}


function Test-Regex {
<#
.Synopsis
Test Regular Expressions.

.Description
A simple helper to test Regular Expressions.

.Parameter String
One or more Strings to test. Excepts piped input.

.Parameter Regex
A .Net compatible Regular Express to test against the strings.

#>
    [CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true
		)]
        [string[]]$String,
	    [Parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true
		)]
        [string]$Regex
    )
    process {
		foreach ($s in $String) {
			if($s -match $RegEx) {
				Write-Output $Matches
			} else {
				Write-Host 'No match found.'
			}
		}
    }
}
