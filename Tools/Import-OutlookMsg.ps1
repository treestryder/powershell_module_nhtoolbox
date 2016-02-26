function Import-OutlookMsg {
<#
.Synopsis
   Imports exported Outlook MSG files into Powershell.

.Notes
    Requires Outlook to be installed.

    See also...
    Outlook Object Model https://msdn.microsoft.com/en-us/library/office/ff866465.aspx
    MailItem Members https://msdn.microsoft.com/en-us/library/office/ff861252.aspx

.Example
    $object = Import-OutlookMsg -Path '.\path\file.msg'
    $object | Get-Member
    $object | Format-List -Property *

#>

    [CmdletBinding()]
    Param (
        # Path or paths to MSG file to import. Excepts piped input.
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [string[]]$Path
    )

    Begin {
        Add-Type -assembly "Microsoft.Office.Interop.Outlook"
        $Outlook = New-Object -TypeName Microsoft.Office.Interop.Outlook.ApplicationClass
        $Mapi = $Outlook.GetNameSpace("MAPI")
    }
    Process {
        foreach ($file in $Path) {
            $MsgObject = $Mapi.Session.OpenSharedItem($file)
            Write-Output $MsgObject
            $MsgObject.Close([Microsoft.Office.Interop.Outlook.OlInspectorClose]::olDiscard)
        }
    }

    End {
        $MsgObject = $null
        $Mapi = $null
        $Outlook = $null
    }
}
