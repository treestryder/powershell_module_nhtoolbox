[CmdletBinding()]
param (
    [string]$Path = (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules\NHToolbox'),
    [switch]$Force
)

if (Test-Path $Path) {
    if ($Force) {
        Remove-Item -Path $Path\* -Recurse
    } else {
        Write-Warning "Module already installed at `"$Path`" use -Force to overwrite installation."
        return
    }
} else {
    New-Item -Path $Path -ItemType Directory | Out-Null
}

Push-Location $PSScriptRoot

Copy-Item -Path * -Destination $Path -Recurse -Exclude .\Install.ps1

Pop-Location

Import-Module -Name NHToolbox -Verbose
