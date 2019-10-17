function Push-GitRepository {
<#
.SYNOPSIS
Used for pushing changes from a branch of a Git Repository to a folder.

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$RepositoryPath,
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        [string]$RefSpec = 'master',
        [switch]$Force
    )

    function Gitify ($Path) { $Path -replace '\\', '/' }

    if ((Test-Path (Join-Path $DestinationPath '.git')) -eq $false) {
        Write-Host "Creating $DestinationPath."
        git clone --branch $RefSpec (Gitify $RepositoryPath) (Gitify $DestinationPath)
    }

    Write-Host "Updating $DestinationPath"
    try {
        Push-Location -Path $DestinationPath -ErrorAction Stop
    }
    catch {
        throw
    }

    git fetch
    git checkout $RefSpec
    git reset --keep "origin/$RefSpec"

    if ($Force) {
        git reset --hard "origin/$RefSpec"
        git clean '-xdf'
    }
    else {
        $differences = (git status -z) -split '\0'
        if ($differences.Count -gt 0) {
            $differencesFormated = $differences -join [System.Environment]::NewLine
            Write-Warning @"
Differences were found at $DestinationPath :
$differencesFormated
"@
        }
    }
    git log '-1'
    Pop-Location      
}
    