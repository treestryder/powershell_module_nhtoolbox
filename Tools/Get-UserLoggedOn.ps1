function Get-UserLoggedOn {
<#
.Synopsis
Lists user accounts in use on a computer.

.Description
Lists user accounts in use on a computer. By default, it only shows accounts 
running Explorer.exe, the traditional Windows Desktop. The -Full parameter 
shows all accounts.

.Parameter ComputerName
Computername to query. Defaults to localhost. Excepts piped input.

.Parameter Full
Lists all accounts found to have a process running, not just those 
running Explorer.exe.

.Example
LTM\Get-UserLoggedOn -ComputerName SomeComputer -Full

Lists all accounts found to have a process running on SomeComputer.

#>
    [CmdletBinding()]
    param(
	    [Parameter(ValueFromPipeline=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
	    [string[]]$ComputerName = '.',
	    [switch]$Full
    )

    process {
		foreach ($c in $ComputerName) {
			Try {
				$process = Get-WMIObject -class win32_process -ComputerName $c -ErrorAction SilentlyContinue
				if ($process) {
					$process | 
					 Where {$Full -or ($_.ExecutablePath -like '*\Explorer.EXE') } |
					  select @{Name='ComputerName';Expression={$_.CSName}}, @{Name='Account';Expression={$_.getowner().domain+'\'+$_.getowner().user}} -unique
				} else {
					Write-Warning "No processes returned from $c."
				}
			}	
			catch {
				Write-Warning "Failed to connect to $c"
				throw $_
			}
		}
	}
}