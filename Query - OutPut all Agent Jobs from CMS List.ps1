<#
 
Query - OutPut all Agent Jobs from CMS List
 
#>
 
IF (!(Get-Module -Name sqlps))
    {
        Push-Location
        Import-Module sqlps -DisableNameChecking
        Pop-Location
    }
 
## Gather all sql instances to query from CMS server
$cmsQuery = @'
SELECT DISTINCT reg.name
FROM msdb.dbo.sysmanagement_shared_registered_servers_internal AS reg 
LEFT JOIN msdb.dbo.sysmanagement_shared_server_groups_internal AS grp
ON grp.server_group_id = reg.server_group_id
WHERE grp.name LIKE '10%'
'@
$instances = invoke-sqlcmd -ServerInstance LON-SQLMON01 -Database msdb -Query $cmsQuery
 
## Always leave a final "\" (C:\temp\)
$ResultsFolder = "C:\SourceTree\DBA\SQL Instance Configuration\Agent Jobs\"
$FailedServers = @()
 
## Loop through all instances and export results to $ResultsFolder
FOREACH ($instance in $instances)
    {
        $i = $instance.Name
        $InstanceFolder = $ResultsFolder + $i


        ## create sub folder
        TRY
            {
                IF (!(Test-Path $InstanceFolder))
                    {
                       New-Item -ItemType directory -Path $InstanceFolder
                    }
                ELSE
                    {
                        Get-ChildItem -Path $InstanceFolder -Include * | remove-Item -recurse 
                    }
 
            }
        CATCH
            {
                Write-Host "error creating sub folder for instance"
            }


        ## load jobs into folder
        TRY
            {
                Write-Host "Writing Results for $i "
                $server = new-object Microsoft.SqlServer.Management.Smo.server $i
                $jobs = $server.jobserver.jobs

                foreach ($job in $jobs) {
                    $fileName = $job.name
                    $outputFile = $instanceFolder + "\" + $fileName + ".sql"
                    $outputFile = $outputFile -replace '[][]',''
                    $job.script() > $outputFile
                }

            }
        CATCH
            {
                Write-Host "Failed on Server $i"
                $FailedServers += $i
            }
    }
 
## List out instances that we failed to export results from
$FailedServers | Out-File $ResultsFolder\Failedinstances.txt
Write-Host "The following instances did not get scripted out (txt list found in $ResultsFolder\Failedinstances.txt)"
Write-Host $FailedServers -BackgroundColor Red -ForegroundColor White


## remove any folders for servers that no longer are in the production CMS list
$CurrentFolders = get-childitem -path $ResultsFolder -Directory 
$FolderNames = $CurrentFolders.name 
$DeleteFolders = Compare-Object $CurrentFolders.name $instances.name 

Foreach ($folder in $DeleteFolders)
    {
        $i = $folder.InputObject
        $fullPath = "$ResultsFolder$i"
        write-host $fullPath  
        Remove-Item $fullPath -Force -Recurse
    }

