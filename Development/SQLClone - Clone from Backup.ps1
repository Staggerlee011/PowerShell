#requires -Version 2 -Modules RedGate.InstantClone.PowerShell


## inputs
##$Db = "itdb"
$DbServer = 'TEL-ETX-PRODDB1'

## Databases to restore
$DeplyDbs = 'PartyDB', 'itdb' , 'Content', 'DataMart', 'Gateway'

## Deploy to local instance
$CloneServer = '.\v2014'
$Source = '\\10.101.1.60\sqlbackup\_CLONES'  

## get date for snapshot name
$date = Get-Date
$date = $date.ToString('yyyyMMdd')

## Configs
IF (!(Get-Module -Name sqlps))
{
  Push-Location
  Import-Module -Name sqlps -DisableNameChecking
  Pop-Location
}



ForEach ($db in $DeplyDbs)
{
  Write-Host -Object "Creating Snapshot for Database: $db at $(Get-Date) "
        
  ###########################################################################################################################
  ## VARIABLES SETTINGS
  ###########################################################################################################################

  # Set the folder locations. SharedSnapshotFolder should be something visible to the machine you want to create the clone on.

  $SourceDatabase = $DbServer + '_' + $db
  $SnapshotName = $SourceDatabase + '_' + $date

  ## CloneDestination
  $CloneDest = 'C:\RedGateClone'

  ## Define backup location
  $BckPath = "\\10.101.1.60\sqlbackup\$DbServer\$db\FULL"

  ###########################################################################################################################
  ## Backup Folder / File 
  ###########################################################################################################################

  ## Test path if fails stop everything someone f£$% up
  IF (!(Test-Path ($BckPath)))
  {
    write-out 'File path does not exist please check spelling of server and database'
    break
  }

  ## Get the latest backup files (if stripped backups used all have the same LastWriteTime
  $BckLatestDate = Get-ChildItem -Path $BckPath  |
  Sort-Object -Property LastWriteTime |
  Select-Object -Last 1
  $BckLatestSet = Get-ChildItem -Path $BckPath  |
  Where-Object -FilterScript {
    $_.LastWriteTime -gt ($BckLatestDate.LastWriteTime).AddSeconds(-2)
  } |
  Sort-Object -Property Name 

  ## populate an array with the paths of the files to use in Save-InstantCloneSnapshot
  $RestoreArray = @()
  foreach ($bkup in $BckLatestSet)
  {
    $RestoreArray += $bkup.FullName
  }

  ###########################################################################################################################
  ## RedGate  
  ###########################################################################################################################

  # Set locations
  Save-InstantCloneOptions -CloneFolder "$CloneDest\Clones" -SnapshotFolder "$CloneDest\SharedSnapshots" -SharedSnapshotFolder "$Source\SharedSnapshots"
  
  # Assuming default instance and trusted auth is ok, change if not 
  $ConnString = "Server=$CloneServer;Trusted_Connection=True"
  Initialize-InstantCloneConnectionString -ConnectionString $ConnString -Verbose
   
  ##Save-InstantCloneSnapshot -BackupPath "\\10.101.1.60\sqlbackup\TEL-ETX-CHRDB01\iTradeDataIndexer\FULL\TEL-ETX-CHRDB01_iTradeDataIndexer_FULL_20160328_181538.bak" -SnapshotName $SnapshotName -Verbose
  Save-InstantCloneSnapshot -BackupPath $RestoreArray -SnapshotName $SnapshotName -PutInSharedFolder -Verbose
  
  # Now share the snapshot to the SMB file share
  Save-InstantCloneSharedSnapshot -SnapshotName $SnapshotName -Verbose


  Write-Host -Object "Creating Clone for database $db at $(Get-Date) "
  # Create Clone database
  New-InstantCloneClone -NewDatabaseName $db -SnapshotName $SnapshotName
}
