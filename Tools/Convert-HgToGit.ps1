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

    hg clone -U $Path $Destination

    Push-Location $Destination
    git init
    $originalExclude = Get-Content -Path '.git/info/exclude' -Raw
    Add-Content -Path '.git/info/exclude' -Value '/.hg/'

    $log = [xml](hg log -T xml -r 0:tip -v)
    foreach ($e in $log.log.logentry) {
        $rev = $e.revision
        $date = $e.date
        $msg = $e.msg.'#text' -replace '"',"'"
        Write-Host
        Write-Host (' ---> Revision {0}: {1}' -f $rev, $msg)
        hg update -v -r $rev
        git add -v --all
        git commit -v -m "$date $msg"
    }

    Set-Content -Path '.git/info/exclude'-Value $originalExclude
    Remove-Item '.hg' -Recurse -Force
    Pop-Location
}