FUNCTION Restart-SQLAgent 
{
<# 
.SYNOPSIS 
Restarts a SQL Server Agent if no jobs are currently running. 

.DESCRIPTION 
Before restarting a SQL Agent it is always important to make sure you are not killing a job that is already running. This script will restart the service or let you know the jobs that are running

THIS CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.

.PARAMETER SqlServer
Allows you to specify a SQL instance to restart its Agent service
	
.NOTES 
Author  : Stephen Bennett
Requires: sysadmin and be in the local adminitration for the server to restart the servce.


.EXAMPLE   
Restart-SqlAgent -SqlServer sqlcluster

Will restart the servers sql agent service if no jobs are currently running
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param (
		[parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $True)]
		[Alias("ServerInstance", "SqlInstance", "SqlServers")]
		[string[]]$SqlServer
	)

     BEGIN
        {
            #Query to find any running jobs 
            $tsql = "SELECT sj.name
                     FROM msdb.dbo.sysjobactivity AS sja
                         INNER JOIN msdb.dbo.sysjobs AS sj
                             ON sja.job_id = sj.job_id
                     WHERE sja.start_execution_date IS NOT NULL
                           AND sja.stop_execution_date IS NULL;"      

           $output = @()

        }

    PROCESS
        {
            
            FOREACH ($Server in $SqlServer)
                {
                    Write-Verbose "Working on Server: $Server"
                    
                    # create output object template
                    $objTemp = New-Object psobject
                    $objTemp | Add-Member -MemberType NoteProperty -Name SQLInstance -Value ""
                    $objTemp| Add-Member -MemberType NoteProperty -Name RestartedAgent -Value ""
                    $objTemp | Add-Member -MemberType NoteProperty -Name FailureReason -Value ""  
                    
                    IF ($Server.contains("\"))
                        {

                             $ServerInstance = $Server.Split("{\}")
                             $hostid = $ServerInstance.Item(0)
                             $instance = $ServerInstance.Item(1)

                             TRY 
                                {
                                    $ipaddr = (Test-Connection $hostid -Count 1 -ErrorAction Stop).Ipv4Address
                                    $hostname = [System.Net.Dns]::gethostentry($ipaddr)
                                    $hostname = $hostname.HostName
                                }
                            CATCH
                                {
                                    Write-Verbose "Failed to connect to: $Server"
                                    $objTemp.SQLInstance = $Server
                                    $objTemp.RestartedAgent = "Failure"
                                    $objTemp.FailureReason = "Could not connect to server"
                                    $output += $objTemp
                                    continue
                                }

                        }
                    ELSE
                        {
                            TRY 
                                {
                                    $ipaddr = (Test-Connection $Server -Count 1 -ErrorAction Stop).Ipv4Address
                                    $hostname = [System.Net.Dns]::gethostentry($ipaddr)
                                    $hostname = $hostname.HostName
                                }
                            CATCH
                                {
                                    Write-Verbose "Failed to connect to: $Server"
                                    $objTemp.SQLInstance = $Server
                                    $objTemp.RestartedAgent = "Failure"
                                    $objTemp.FailureReason = "Could not connect to server"
                                    $output += $objTemp
                                    continue
                                }
                        }

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                    $SqlConnection.ConnectionString = "Server=$Server;Database=msdb;Integrated Security=True"
                    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
                    $SqlCmd.CommandText = $Tsql
                    $SqlCmd.Connection = $SqlConnection
                    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
                    $SqlAdapter.SelectCommand = $SqlCmd
                    $RunningJobs = New-Object System.Data.DataSet
                    $null = $SqlAdapter.Fill($RunningJobs)
                    $SqlConnection.Close()
                    $jobsRunning = $RunningJobs.Tables[0].Rows.Count

                    # restart service 
                    IF (!($jobsRunning))
                       {
                           IF(!( $Server.contains("\")))
                               {
                                   Write-Verbose "Restarting SQL Agent Service on: $Server"
                                   Get-Service -ComputerName $hostname SQLSERVERAGENT | Restart-Service -WarningAction SilentlyContinue 
                                   $objTemp.SQLInstance = $Server
                                   $objTemp.RestartedAgent = "Success"
                                   $objTemp.FailureReason = ""
                               }
                           ELSE
                               {
                                   $NamedSQLAgent = "SQLAgent$" + $instance
                                   Write-Verbose "Restarting SQL Agent Service : $NamedSQLAgent"
                                   Get-Service -ComputerName $hostname $NamedSQLAgent | Restart-Service -WarningAction SilentlyContinue 
                                   $objTemp.SQLInstance = $Server
                                   $objTemp.RestartedAgent = "Success"
                                   $objTemp.FailureReason = ""
                               }
                       }
                    ELSE
                       {
                            Write-verbose "There are jobs running on Agent please wait till they are finished on: $server"
                            [string] $jobs = "Jobs Running ||"
                            $loop = 0

                            WHILE ($loop -lt $jobsRunning)
                                {
                                    $i = $RunningJobs.Tables[0][$loop].name
                                    $jobs = "$jobs $i ||"
                                    $loop ++
                                }

                            $objTemp.SQLInstance = $Server
                            $objTemp.RestartedAgent = "No"
                            $objTemp.FailureReason = "$jobs"
                       }
                    $output += $objTemp
                }
        }

    END
        {
            return ($output)
        }
}   
