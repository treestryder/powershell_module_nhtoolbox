function Set-ADUserPhoto {
    <#
    .SYNOPSIS
        Crops, resizes and updates an Active Directory Thumbnail Photo.
    #>
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Identity,
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Path,
            [switch]$WhatIf
        )
        
        # Handle FileInfo and String input.
        if ($Path -isnot [System.IO.FileInfo]) {
            $Path = [System.IO.FileInfo]$Path
        }
        
        if (-not (Test-Path -Path $Path)) {
            throw "File not found: $Path"
        }
    

        try {
            [byte[]]$photo = ConvertTo-JPEGThumbnail -Path $Path
        }
        catch {
            throw ('Failed to crop and resize photo: {0}' -f $_.ToString())
        }
    
        try {
            Set-ADUser -Identity $Identity -Replace @{thumbnailPhoto=$photo} -ErrorAction Stop -WhatIf:$WhatIf
        }
        catch {
            throw ('Failed to set AD user photo: {0}' -f $_.ToString())
        }
    }
    
    