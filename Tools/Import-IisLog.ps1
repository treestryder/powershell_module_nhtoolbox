function Import-IISLog {
<#
.Synopsis
Imports a IIS web log, turning it into Powershell custom objects.

.Description
Imports a IIS web log, turning it into Powershell custom objects. Also
converts the date and time fields into Local Time.

.Parameter Path
One or more file paths to import. Excepts piped input.

.Example
Import-IISLog -Path ex131018.log

.Example
Get-ChildItem '*.log' | Import-IISLog

#>
    [CmdletBinding()]
    param(
	    [Parameter(ValueFromPipeline=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path
    )
    process {
        get-content $Path |
         ForEach {$_ -replace '#Fields: ', ''} |
          Where {$_ -notmatch '^#'} | ConvertFrom-Csv -Delimiter ' ' |
           ForEach {
		    $localTime = $(
			    try {
				    (Get-Date ('{0} {1}' -f $_.date, $_.time)).ToLocalTime()
			    }
			    catch {}
		    )
		    $_ | Add-Member -MemberType NoteProperty -Name 'LocalTime' -Value $localTime
		    $_
	    }
    }
}