function Invoke-CreatorSQLScripts {
<#
.SYNOPSIS 
Runs all .sql file in a folder/sub folder against master database

.DESCRIPTION
runs all .sql scripst using sort-object for order 

.PARAMETER SqlServer
Name of SQL Server Instance you wish to run the scripts against

.PARAMETER Path
Path to root folder example C:\Temp

.PARAMETER Recurse
Recurse the root folder to find sql files in all other files

.PARAMETER SqlCredential
Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted. To use:

$scred = Get-Credential, then pass $scred object to the -SourceSqlCredential parameter. 

Windows Authentication will be used if DestinationSqlCredential is not specified. SQL Server does not accept Windows credentials being passed as credentials. 	
To connect as a different Windows user, run PowerShell as that user.

.PARAMETER WhatIf 
Shows what would happen if the command were to run. No actions are actually performed. 

.NOTES 
Author: Stephen.Bennett

.LINK


.EXAMPLE   
Invoke-CreatorSQLScripts -Path C:\Temp -Recurse

Loops over all folders in the C:\Temp and runs every .sql found

.EXAMPLE   
$secpasswd = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$SACred = New-Object System.Management.Automation.PSCredential ("sa", $secpasswd)
Invoke-CreatorSQLScripts -Path C:\Temp -Recurse -SqlCredential SACred

Loops over all folders in the C:\Temp and runs every .sql found using the sa login to authenticate with the SqlServer 

#>
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
	param (
		[parameter(Mandatory = $true)]
		[Alias("ServerInstance", "SqlInstance", "SqlServers")]
		[object]$SQLServer,
		[parameter(Mandatory = $true)]
		[object]$Path,
		[switch]$Recurse,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
    BEGIN
    {
        # Get DbaTools
        if ((Get-Module -ListAvailable -Name dbatools).Count -ge 1) 
        {
            # Import the modules
            Import-Module dbatools
      
        } else {
            Write-Warning "dbatools not installed, this is used for connecting to the SQL host, please install via: Install-Module Dbatools"
            break
        }

        # test path exists
        if (Test-Path $Path)
        {
            Write-verbose "Test-Path Passed"
        } else {
            Write-Warning "Test-Path failed for the location you used in $Path please check file path"
            break
        }
    } # end begin
    PROCESS
    {

        # Create connection to SQL instance
        try
        {
            $srv = Connect-DbaSqlServer -SqlServer $SQLServer -Credential $Credential
        }
        catch
        {
            throw New-Object System.Exception("Failed to Connect to SQL instance: | $($_.Exception.Message)", $_.Exception)
            break
        }

        ## list files
        ## Run all SQL Scripts
        if ($Recurse)
        {
            $folders = Get-ChildItem $Path -Directory | Sort-Object 

            Foreach ($folder in $folders)
            {
                $sqlfiles = Get-ChildItem $folder.FullName | Where-Object {$_.Extension -eq ".sql"} | Sort-Object 
                Write-Verbose "Running SQL Scripts from $folder"
                foreach ($sqlfile in $sqlfiles)
                {
                    $f = $sqlfile.FullName
                    If ($Pscmdlet.ShouldProcess($SqlServer, "Executing $f"))
                    {
                        try 
                        {
                            Write-Verbose "Running $f"
                            $script = Get-Content -Path $f -Raw
                            $srv.Databases["master"].ExecuteNonQuery($script)
                            $scriptSuccess = "Success"        
                        }
                        catch 
                        {
                            Write-Warning $_.Exception
                            $scriptSuccess = "Failure: $_.Exception" 
                        }
 
                        [PSCustomObject]@{
		    		        SQLServer = $SqlServer
                            Script = $sqlfile
		    		        Completed = $scriptSuccess
                        }
                    }
                } # foreach file
            } # foreach folder
        } else {
            $sqlfiles = Get-ChildItem $folder | Where-Object {$_.Extension -eq ".sql"} | Sort-Object 
            Write-Verbose "Running SQL Scripts from $folder"
            foreach ($sqlfile in $sqlfiles)
            {
                $f = $sqlfile.FullName
                If ($Pscmdlet.ShouldProcess($SqlServer, "Executing $f"))
                {
                    try 
                    {
                        Write-Verbose "Running $f"
                        $script = Get-Content -Path $f -Raw
                        $srv.Databases["master"].ExecuteNonQuery($script)
                        $scriptSuccess = "Success"        
                    }
                    catch 
                    {
                        Write-Warning $_.Exception
                        $scriptSuccess = "Failure: $_.Exception" 
                    }
 
                    [PSCustomObject]@{
		    	        SQLServer = $SqlServer
                        Script = $sqlfile
		    	        Completed = $scriptSuccess
                    }
                }
            } # foreach file

        }
    } # end process
} # end scripts