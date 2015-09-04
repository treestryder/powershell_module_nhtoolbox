#
# Get-RelativePath.ps1
#


function Get-RelativePath {
<#
 .Synopsis
 Returns the relative path names, based on the current directory, as strings.

 .Description
 Returns the relative path names, based on the current directory, as strings.

 .Example
 cd c:\somePath\
 Get-RelativePath -Recurse

#>
	[CmdletBinding()]
    param (
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True
		)]
        $Path = '.',
        $Filter,
        $Exclude,
        [switch]$Force,
        $Include,
        [switch]$Recurse,
        [switch]$Directory,
        [switch]$File
    )
    
    process {
        Foreach ($p in $Path) {
            if ( [System.IO.FileInfo], [System.IO.DirectoryInfo] -contains $p.GetType() ) {
                $p = $_.FullName
            }
            # The default root is the current directory. This changes the root when the requested path does not match the current directory, does not contain wild cards and is a directory. Doesn't work for directories like C:\
            #if ( -not $p.StartsWith((Get-Location).ProviderPath) -and $p -notmatch '[\*\?]' -and (Get-Item -Path $p).PSIsContainer) {
            #    Resolve-Path $p | Foreach {
            #        Get-RelativePath -Path $_.ProviderPath -Filter:$Filter -Exclude:$Exclude -Force:$Force -Include:$Include -Recurse:$Recurse -Directory:$Directory -File:$File
            #    }
            #    continue
            #} else {
            $root = (Get-Location).ProviderPath
            #}
            $root = $root -replace '\\\$', ''
            $pr = (Resolve-Path $p).ProviderPath
            if ($pr -is [array]) {
                Write-Error "Wild cards are not allowed: $p"
                continue
            }

            if ( -not $pr.StartsWith($root) ) {
                Write-Error "The root directory $root does not match the path $pr . Change directory to your starting point."
                continue
            }
            Write-Debug "Using root: $root"
            Get-ChildItem -Path $pr -Filter:$Filter -Exclude:$Exclude -Force:$Force -Include:$Include -Recurse:$Recurse | Where {
                (-not $Directory -and -not $File) -or
                ($Directory -and $_.PSIsContainer -eq $true) -or
                ($File -and $_.PSIsContainer -eq $false)
            } | Foreach {
                if ($_.FullName.Length -ge $root.Length) {
                    Write-Output $_.FullName.Substring($root.Length + 1)
                } 
            }
        }
    }
}
