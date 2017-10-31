function Get-DbaSev20 {
<#
.SYNOPSIS 
Returns the user domain and source computer for the severity 20 alert

.DESCRIPTION
Queries Get-WinEvent on 

.PARAMETER SqlServer
Name of SQL Server Instance you wish to run the scripts against

.PARAMETER MaxEvents
Max number of events you wish to return

.NOTES 
Author: Stephen.Bennett

.EXAMPLE   
Get-DbaSev20 -SqlInstance MyServer -MaxEvents 5

Returns at max the last 5 severity 20 alerts on MyServer

#>
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
	param (
		[parameter(Mandatory = $true)]
		[Alias("ServerInstance", "SqlInstance", "SqlServers")]
		[object]$SQLServer = "Dev-sql-msd02",
		[int]$MaxEvents = 5
	)

    process
    {
        $outputs = Get-WinEvent -ComputerName $SQLServer -FilterHashtable @{logname='Security'; id='4625'} -MaxEvents $MaxEvents 
        ## text manipulation
        
        foreach ($output in $outputs)
        {
            $fulltext = $outputs[0].Message 
            $split = $fulltext -split '[\r\n]'
            $AccountName = $split -match "Account Name:"
            $DomainName = $split -match "Account Domain:"
            $workstation = $split -match "Workstation Name:"
            
            $out = [pscustomobject]@{
                User = $AccountName[1] -replace '\s','' -replace 'AccountName:',''
                Domain = $DomainName[1] -replace '\s','' -replace 'AccountDomain:',''
                WorkStation = $workstation[0] -replace '\s','' -replace 'WorkstationName:',''
            }
            $out
        }
    }
}
