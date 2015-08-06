
Import-Module "$PSScriptRoot/Tools/*.psm1"
Get-ChildItem "$PSScriptRoot/Tools/*.ps1" | foreach { . $_ }
