<#
 
Query - sp_help_revlogin Export Results to File
 
#>
 
IF (!(Get-Module -Name sqlps))
    {
        Push-Location
        Import-Module sqlps -DisableNameChecking
        Pop-Location
    }
 
## Gather all sql instances to query from CMS server
$cmsQuery = @'
SELECT DISTINCT name
FROM msdb.dbo.sysmanagement_shared_registered_servers_internal
ORDER BY name
'@
$instances = invoke-sqlcmd -ServerInstance LON-SQLMON01 -Database msdb -Query $cmsQuery
 
## Always leave a final "\" (C:\temp\)
$ResultsFolder = "C:\SourceTree\DBA\SQL Instance Configuration\Logins\"
$FailedServers = @()

## remove all current scripts
Get-ChildItem -Path $ResultsFolder -Include * | remove-Item -recurse 

## Loop through all instances and export results to $ResultsFolder
FOREACH ($instance in $instances)
    {
        $i = $instance.Name
        TRY
            {
                $serverName = $i -replace '\','-'
                $fileName = $ResultsFolder + $serverName + ".txt"
                write-host "Writing Results for $i "
                Invoke-Sqlcmd -ServerInstance $i -Database master -Query "sp_help_revlogin" -Verbose 4> $fileName
            }
        CATCH
            {
                write-host "Failed on Server $i"
                $FailedServers += $i
            }
    }
 
## List out instances that we failed to export results from
$FailedServers | Out-File $ResultsFolder\Failedinstances.txt
Write-Host "The following instances did not get scripted out (txt list found in $ResultsFolder\Failedinstances.txt)"
Write-host $FailedServers -BackgroundColor Red -ForegroundColor White