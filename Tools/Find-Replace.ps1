function Find-Replace {
<#
.SYNOPSIS
Finds and Replaces multiple entries, in multiple files.

.DESCRIPTION
By default, performs an ordinal (case-sensitive and culture-insensitive) search to find an old value and replace it.

.PARAMETER Path
One or more files Paths to process. Excepts values from the Pipeline. Will except the output from Get-ChildItem.

.PARAMETER Object
Any object or array of objects with Find and Replace properties that will be used to make the swap.
-Object (Import-CSV SomeFile.csv)
-Object @{Find = 'this'; Replace = 'that'}, @{Find = 'something'; Replace = 'other'}

.PARAMETER Find
One or more strings to Find.

.PARAMETER Replace
A string to replace those matching -Find.

.PARAMETER Regex
Treat find values as Regular Expressions.

.PARAMETER WhatIf
Test Find and Replace without making any changes.

.PARAMETER Backup
Backup the original file to <OriginalFileName>_yyyyMMddHHmmss.

.PARAMETER PassThru
Passes changed (or needing to be changed with WhatIf enabled) files through the pipeline.

.PARAMETER Encoding
Specifies the file encoding. The default is ASCII.
    
    Valid values are:
    
    -- ASCII:  Uses the encoding for the ASCII (7-bit) character set.
    -- BigEndianUnicode:  Encodes in UTF-16 format using the big-endian byte order.
    -- Byte:   Encodes a set of characters into a sequence of bytes.
    -- String:  Uses the encoding type for a string.
    -- Unicode:  Encodes in UTF-16 format using the little-endian byte order.
    -- UTF7:   Encodes in UTF-7 format.
    -- UTF8:  Encodes in UTF-8 format.
    -- Unknown:  The encoding type is unknown or invalid. The data can be treated as binary.

.INPUTS
Excepts file names and file objects for the Path parameter.

.OUTPUTS
None, unless PassThru specified. With PassThru, passes changed (or needing to be changed with WhatIf enabled) files through the pipeline.

.EXAMPLE
Get-ChildItem SomePath\* -recurse -include *.config,*.xslt,*.xml,*.txt | LTM\Find-Replace.ps1 -Object (Import-Csv Replacements.csv) -PassThru | set-content ChangedFiles.txt

#>
    [CmdletBinding(DefaultParametersetName="string")]
    param (
	    [Parameter(
		    Mandatory=$True,
		    ValueFromPipeline=$True,
		    ValueFromPipelineByPropertyName=$True,
		    Position=0,
		    HelpMessage="One or more file Paths to process."
	    )]
	    [string[]]$Path,

	    [Parameter(
		    ParameterSetName="object",
		    Mandatory=$True,
		    Position=1,
		    HelpMessage="Any object or array of objects with Find and Replace properties that will be used to make the swap."
	    )]
	    $Object,

	    [Parameter(
		    ParameterSetName="string",
		    Mandatory=$True,
		    Position=1,
		    HelpMessage="An array of strings to Find."
	    )]
	    [string[]]$Find,
	    [Parameter(
		    ParameterSetName="string",
		    Mandatory=$False,
		    Position=2,
		    HelpMessage="A string to replace those matching -Find."
	    )]
	    [string]$Replace,

	
	    [Parameter(	HelpMessage="Treat find values as Regular Expressions." )]
	    [switch]$Regex,
	
	    [Parameter(	HelpMessage="Test Find and Replace without making any changes." )]
	    [switch]$WhatIf,
	
	    [Parameter(	HelpMessage="Backup the original file to <OriginalFileName>_yyyyMMddHHmmss." )]
	    [switch]$Backup,
	
	    [Parameter(	HelpMessage="Passes changed (or needing to be changed with WhatIf enabled) files through the pipeline." )]
	    [switch]$PassThru,
	
	    [string]$Encoding = 'ASCII'
    )

    BEGIN {
        $replaceCache = @()
	    if ($PsCmdlet.ParameterSetName -eq 'string') {
		    [array]$replaceCache = @($Find | Foreach { [pscustomobject]@{find=$_; replace=$Replace} })
	    } else {
		    [array]$replaceCache = @($Object | Where {$_.Find -is [string] -and $_.Find.length -gt 0 -and $_.Replace -is [string] } | Foreach { [pscustomobject]@{find=$_.find; replace=$_.replace}})
	    }
	    if ($replaceCache.count -lt 1) {
		    Write-Warning 'No find values found or specified.'
		    Exit
	    }
	    $numFiles = 0
	    $numLines = 0
	    $numFilesChanged = 0
	    $numLinesChanged = 0
	    $RunTime = Get-Date
    }

    PROCESS {
    $Path | foreach {
		    $file = $_
		    Write-Verbose "Processing $file"
		    $numFiles++
		    $lineNum = 0 
		    $changesNum = 0
		    Get-Content $file | Foreach {
			    $line = $_
			    $lineNum++
			    Write-Debug $('{0:  0}: {1}' -f $lineNum, $line)
			    $replaceCache | Foreach {
				    $replace = $_
				    $replace
				    Write-Debug $('Find: [{0}]  Replace: [{1}]' -f $replace.find, $replace.replace)
				    if ($Regex) {
					    $line = $line -replace $replace.find, $replace.replace
				    } else {
					    $line = $line.Replace($replace.find, $replace.replace)
				    }
			    }
			    if ($_ -cne $line) {
				    $changesNum++
				    Write-Verbose "   Changed line $lineNum from '$_' to '$line' in $file."
			    }
			    $line
		    } | Where {-not $WhatIf} | Set-Content -encoding:$Encoding -Path ($file + '_FindReplace')
		    $numLines += $lineNum
		    $numLinesChanged += $changesNum
		    if ($changesNum -gt 0) {
			    $numFilesChanged++
			    if (-not $WhatIf) {
				    if ($Backup) {
					    Copy-Item ($file + '_FindReplace') ('{0}_{1:yyyyMMddHHmmss}' -f $file, $RunTime) -Verbose:$Verbose
				    }
				    Remove-Item $file
				    Rename-Item ($file + '_FindReplace') $file
				    Write-Verbose "    Changed $changesNum of $lineNum Lines"
			    }
			    if ($PassThru) { $file }
		    }
	    }
    }

    END {
	    $totals = "Totals: Changed $numFilesChanged of $numFiles Files  Changed $numLinesChanged of $numLines Lines"
	    if ($WhatIf) {
		    Write-Host "What if: $totals"
	    } else {
		    Write-Verbose $totals
	    }
    }
}
