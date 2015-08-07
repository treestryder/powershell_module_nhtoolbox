function Add-Journal {
<#
.Synopsis
Adds an entry to a journal file, for hyper-simple note taking.

#>
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			Position=0
		)]
		[alias('Entry','Note','InputObject')]
		[object[]]$Value,
		[object]$Path = (Join-Path ([environment]::getfolderpath('mydocuments')) 'Journal.txt')
	)

	begin {
		$header = '### {0:G} {1}' -f (Get-Date), ([Security.Principal.WindowsIdentity]::GetCurrent().Name)
		Add-Content -Path $Path -Value $header
	}

	process {
		Add-Content -Path $Path -Value $value
	}

	end {
		Add-Content -Path $Path -Value ''
	}
}
Set-Alias -Name Add-Journal -Value aj
Export-ModuleMember -Function Add-Journal -Alias aj


function Get-Journal {
<#
.Synopsis
Retrieves the journal file in various ways.

#>
    [CmdletBinding()]
	param (
		[object]$Path = (Join-Path ([environment]::getfolderpath('mydocuments')) 'Journal.txt'),
		[switch]$Edit,
		[switch]$File
	)
	if ($File) {
		Resolve-Path $Path
		return
	} elseif ($Edit) {
		Invoke-Item $Path
		return
	} else {
		Get-Content $Path
		return
	}
}
Export-ModuleMember -Function Get-Journal
