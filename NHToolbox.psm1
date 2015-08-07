
Get-ChildItem "$PSScriptRoot/Tools/*.psm1" | foreach { Import-Module $_ }
Get-ChildItem "$PSScriptRoot/Tools/*.ps1" | foreach { . $_ }
