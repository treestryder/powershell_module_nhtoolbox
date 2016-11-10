<#
.Synopsis
    Adds access rules to a folder.
.Example
    Add-AclAccessRule -Username 'SamAccountName' -Permission Modify -Path 'C:\Some\Path'
.Notes
    TODO: Allow piped input.
    TODO: Parameters for inheritence.
    TODO: Make work for files.
#>

function Add-AclAccessRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            Test-Path -Path $_ -PathType Container
        })]
        $Path,
        [Parameter(Mandatory=$true)]
        $SamAccountName,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Read','Modify')]
        $Permission
    )
    $acl = Get-Acl -Path $Path
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($SamAccountName, $Permission, "ContainerInherit, ObjectInherit", "None", "Allow")))
    Set-Acl -Path $Path -AclObject $acl
}