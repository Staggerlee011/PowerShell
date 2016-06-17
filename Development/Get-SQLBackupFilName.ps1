<#
.Synopsis
   Finds backup for database based on date and name
.DESCRIPTION
   looks through the central database backup storage to find backup (works with stripped backups) to output results in array
.EXAMPLE
   Get-SQLBackupFilName -Database Test
.EXAMPLE
   Get-SQLBackupFilName -Database Test -Date 2016-04-10
.INPUTS
   Database
.OUTPUTS
   Date
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SQLBackupFilName
{
   
        [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Instance,
        [Parameter(Mandatory=$true)]
        [string]$Database
    )

    Begin
    {
        ## Path to database backup files based on current standard of Ola H scripts 
        $BckPath = "\\10.101.1.60\sqlbackup\$Instance\$Database\FULL"

        ## Test path if fails stop everything someone f£$% up
        IF (!(Test-Path ($BckPath)))
            {
                write-host 'File path does not exist please check spelling of the instance and database'
                break
            }


    }
    Process
    {

      ## Get the latest backup files (if stripped backups used all have the same LastWriteTime
      $BckLatestDate = Get-ChildItem -Path $BckPath  |  Sort-Object -Property LastWriteTime | Select-Object -Last 1
      $BckLatestSet = Get-ChildItem -Path $BckPath  |  Where-Object -FilterScript  {  $_.LastWriteTime -gt ($BckLatestDate.LastWriteTime).AddSeconds(-2)  } | Sort-Object -Property Name 

      ## populate an array with the paths of the files to use in Save-InstantCloneSnapshot
      $RestoreArray = @()
      foreach ($bkup in $BckLatestSet)
          {
            $RestoreArray += $bkup.FullName
          }

    }
    End
    {
        return $RestoreArray
    }
}