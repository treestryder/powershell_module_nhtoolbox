﻿<#
.Synopsis
   New-IISWebApp
.EXAMPLE
   
#>
function New-IISWebApp
{
    [CmdletBinding()]
    param (
        # Param1 help description
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Path,
        [PSCredential]$Credential
    )

    begin {
        Import-Module WebAdministration
        Backup-WebConfiguration -Name ('Backup_{0:yyyyMMddHHmm}' -f (Get-Date))
    }

    process {
        Write-Verbose ('Creating web app [{0}] with port [{1}] path [{2}] user [{3}].' -f $Name, $Port, $Path, $Credential.UserName)
        $appPoolName = $Name + '-AppPool'
        if ( Get-ChildItem IIS:\\Sites | where {$_.Name -eq $Name} ) {
            throw 'Site already exists.'
        }

        if ( Get-ChildItem IIS:\\AppPools | where {$_.Name -eq $appPoolName}) {
            throw 'AppPool already exists.'
        }

        try {
            $appPool = New-WebAppPool -Name $appPoolName

            $appPool | Set-ItemProperty -name processModel -value @{
                userName=$Credential.Username
                password=$Credential.GetNetworkCredential().Password
                identitytype=3
            }
   
	        # Prefered app pool recycling settings.
	        $appPool | Set-ItemProperty -Name processModel -value @{idletimeout="0"}
	        $appPool | Set-ItemProperty -Name Recycling.periodicRestart -Value @{time="00:00:00"}
	        $appPool | Set-ItemProperty -Name Recycling -value @{logEventOnRecycle="Time, Requests, Schedule, Memory, IsapiUnhealthy, OnDemand, ConfigChange, PrivateMemory"}
           
            New-Website -Name $Name -Port $Port -ApplicationPool $appPoolName -PhysicalPath $Path
        }
        catch {
            throw
        }
    }
}