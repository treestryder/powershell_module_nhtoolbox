function Write-Log {
<#
.Synopsis
Writes strings to a file. By default the written string is prefaced with the time and date. 

.Parameter InputObject
Log entry. Non-string objects have the .ToString() method called.

.Parameter Path
Path to the log file.

.Parameter LineTemplate
String with the following .Net format tokens available.
{0} = $InputObject
{1} = Get-Date
{2} = $env:ComputerName
{3} = $env:UserName
{4} = $env:UserDomain

.Parameter Passthru
Writes the formatted string to the log file and passes the string to the default output stream.

.Parameter Verbose
Writes the formatted string to the log file and passes the string to the Verbose output stream.

#>
   
    param (
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        [object[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$LineTemplate = '{1:G} {0}',
        [switch]$PassThru
    )
    
     process {
        foreach ($o in $InputObject) {
            $line = $LineTemplate -f $o, (Get-Date), $env:COMPUTERNAME, $env:UserName, $env:UserDomain
            Write-Verbose $line
            Add-Content -Value $line -Path $Path -PassThru:$PassThru
        }
    }
}
