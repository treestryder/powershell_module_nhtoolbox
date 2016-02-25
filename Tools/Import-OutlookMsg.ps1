function Import-OutlookMsg {
<#
.Synopsis
   Imports Outlook MSG export formated files.

.Notes
    Requires Outlook to be installed.

.Example
    Import-OutlookMsg -Path 'C:\Users\nhartley\Downloads\DANGER\SpearPhishingAttempt-Attached_Image.msg'

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
