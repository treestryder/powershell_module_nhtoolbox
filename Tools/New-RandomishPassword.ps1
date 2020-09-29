function New-RandomishPassword {
    param (
        [int]$Length = 12,
        [string]$Characters = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQURSTUVWXYZ23456789~!@#$%^&*()_-+={[}]|:;<,>/\.?',
        [switch]$AsPlainText
    )

    $password = (Get-Random -InputObject $Characters.ToCharArray() -Count $Length) -join ''

    if ($AsPlainText) {
        $password | Write-Output
    }
    else {
        ConvertTo-SecureString -String $password -AsPlainText -Force | Write-Output
    }
}
