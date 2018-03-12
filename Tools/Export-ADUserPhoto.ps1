function Export-ADUserPhoto {
    <#
    .SYNOPSIS
        Exports a thumbnail photo from Active Directory.
    .NOTES
        Requires the ActiveDirectory Module.
    #>
    [CmdletBinding()] 
    param (
        [Parameter(Mandatory=$true)]
        $Identity,
        [Parameter(Mandatory=$true)]
        [ValidatePattern('\.jpg$|\.jpeg$')]
        [string]$Path
    )

    try {
        $user = Get-ADUser -Identity $Identity -Properties ThumbnailPhoto -ErrorAction Stop
    }
    catch {
        throw ('Identity not found: {0}' -f $_.ToString())
    }
    $user.ThumbnailPhoto | Set-Content -Path $Path -Encoding Byte
}
