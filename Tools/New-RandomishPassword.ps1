function New-RandomishPassword {
    param (
        [int]$Length = 10,
        [string]$Characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQURSTUVWXYZ1234567890~!@#$%^&*()_-+={[}]|:;<,>/\.?'
    )

    $password = New-Object System.Text.StringBuilder

    for ($i = 0; $i -lt $Length; $i++) {
        $c = Get-Random -Minimum 0 -Maximum $characters.Length
        $null = $password.Append($Characters[$c])
    }
    return $password.ToString()
}