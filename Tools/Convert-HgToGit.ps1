function Convert-HgToGit {
<#
.Synopsis
    Simple replay conversion of a Mercurial repository to a Git repository.

.Example
    Convert-HgToGit .\ExistingMercurialRepository .\NewGitRepository

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Destination
    )


    if (Test-Path $Destination) {
        #Remove-Item $Destination -Force -Recurse
        throw "The Git Path should not exist: $Destination"
    }

    'Cloning Mercurial repository {0} to {1}' -f $Path, $Destination | Write-Verbose
    hg clone -U $Path $Destination

    Push-Location $Destination
    'Initializing Git repository.' | Write-Verbose
    &{
        Invoke-Git init
    } | Write-Verbose
    
    $hadOriginalExclude = $false
    if (Test-Path '.git/info/exclude') {
        $hadOriginalExclude = $true
        $originalExclude = Get-Content -Path '.git/info/exclude' -Raw
    }
    Add-Content -Path '.git/info/exclude' -Value '/.hg/'

    'Gathering Mercurial logs.' | Write-Verbose
    $log = [xml](hg log -T xml -r 0:tip -v)
    foreach ($e in $log.log.logentry) {
        $rev = $e.revision
        $date = $e.date
        $msg = $e.msg.'#text' -replace '"',"'"
        Write-Host
        Write-Host (' ---> Revision {0}: {1}' -f $rev, $msg)
    
        'Updating Mecurial state.' | Write-Verbose
        &{
            hg update -r $rev
        } | Write-Verbpse
        'Adding any missing files.' | Write-Verbose
        &{
            Invoke-Git add --all
            Invoke-Git commit -m "$date $msg"
        } | Write-Verbose
    }

    if ($hadOriginalExclude) {
        Set-Content -Path '.git/info/exclude'-Value $originalExclude
    }
    Remove-Item '.hg' -Recurse -Force
    Pop-Location
}
