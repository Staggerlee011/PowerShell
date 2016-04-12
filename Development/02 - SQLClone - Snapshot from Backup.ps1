# Set the folder locations. SharedSnapshotFolder should be something visible to the machine you want to create the clone on.  
$MyDocuments  = [environment]::getfolderpath("mydocuments")
$SourceDatabase = 'LON-SQL01-InstanceState'
$SnapshotName = 'LON-SQL01-InstanceState-Snapshot'


Save-InstantCloneOptions `
    -CloneFolder "$MyDocuments\Red Gate Instant Clone\Clones" `
    -SnapshotFolder "$MyDocuments\Red Gate Instant Clone\Snapshots" `
    -SharedSnapshotFolder "$MyDocuments\Red Gate Instant Clone\Snapshots"
 
Show-InstantCloneOptions -Verbose
   
# Define connection to instance. Mine is \Dev.
Initialize-InstantCloneConnectionString `
    -ConnectionString 'Server=.\v2014;Trusted_Connection=True'   -Verbose
 
$elapsed = [System.Diagnostics.Stopwatch ]::StartNew()
 
Write-host "Started at $(get-date) "
  
New-InstantCloneClone -NewDatabaseName InstanceState-Clone -SnapshotName $SnapshotName
 
Write-Host 'Clone created'
Write-host "Total Elapsed Time: $($elapsed.Elapsed.ToString()) "