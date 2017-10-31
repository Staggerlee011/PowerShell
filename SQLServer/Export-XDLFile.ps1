function Export-XDLFile {
<#
.SYNOPSIS 
Creates .xdl files to read deadlock graphs from the Event Notification Table 

.DESCRIPTION
Parses the xml from the Admin.dbo.NotificationLog table and exports a .xdl file per deadlock found to your choosen path

.PARAMETER SqlServer
Name of SQL Server Instance you wish to run the scripts against (allows muultiple servers to set or piped in 

.PARAMETER Path
Path to root folder example C:\Temp

.PARAMETER SqlCredential
Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted. To use:

$scred = Get-Credential, then pass $scred object to the -SourceSqlCredential parameter. 

Windows Authentication will be used if DestinationSqlCredential is not specified. SQL Server does not accept Windows credentials being passed as credentials. 	
To connect as a different Windows user, run PowerShell as that user.

.PARAMETER Force
Overwrite files in the folder with same name

.NOTES 
Author: Stephen.Bennett

.EXAMPLE   
Export-XDLFile -SqlInstance test-Server -Table admin.dbo.notificationlog -Path "C:\Temp" -Force -Verbose

Outputs any deadlocks grapths on the Test-Server to c:\Temp and overwrites any existing files

.EXAMPLE   
Get-DbaRegisteredServer -SqlInstance prd-sql-int01 -Group '01 - Google Production' | select -ExpandProperty ServerName | Export-XDLFile -Table admin.dbo.notificationlog -Path "C:\Temp" -Force -Verbose

Outputs xdl files for every deadlock found on all any server in "01 - Google Production"
#>
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Alias("ServerInstance", "SqlInstance", "SqlServers")]
		[object[]]$SQLServer,
		[parameter(Mandatory = $true)]
		[string]$Path,
		[parameter(Mandatory = $true)]
		[string]$Table,
		[System.Management.Automation.PSCredential]$SqlCredential,
        [switch]$Force
	)
    begin
    {
        Write-Verbose "Set to overwrite files with the same name is $force"
        $Query = "SELECT EventTime, [FullLog].query('/EVENT_INSTANCE/TextData/deadlock-list') FROM $Table WHERE EventType LIKE 'DEADLOCK_GRAPH'"
        # test path exists
        if (Test-Path $Path)
        {
            Write-verbose "Test-Path Passed"
        } else {
            Write-Warning "Test-Path failed for the location you used in $Path please check file path"
            break
        }
    }
    process
    {
 
        foreach ($Server in $SQLServer)
        {
            Write-Verbose "Connecting to Server: $Server"
            $srv = Connect-DbaInstance -SqlInstance $Server -Credential $SqlCredential
            
            try
            {
                $results = $srv.Databases["Admin"].Query($Query) 
            }
            catch
            {
                Write-Output "Failed to connect to table: $table on Server: $server"
                break
            }
            $resultCount = $results.Column1.Count
            write-output "There are $resultCount xld files to create on server $Server"
          
            foreach ($result in $results)
            {
                $et = $result.EventTime -replace "/", "-" -replace ":","-"
                $filename = $Server + " " + $et + ".xdl"    
                Write-Verbose "Creating $filename"
                
                if ($Force)
                {
                    New-Item -Path $Path -Name $filename -Value $result.Column1 -Force | Out-Null
                }
                else
                {
                    try 
                    {
                        New-Item -Path $Path -Name $filename -Value $result.Column1 -ErrorAction Stop | Out-Null
                    }
                    catch
                    {
                        Write-Output "Error writing file $filename"  
                        $_ 
                    }
                }
            }
        } # foreach sqlserver
    } # process
} # close function