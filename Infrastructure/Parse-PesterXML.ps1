function Parse-PesterXML {
<#
.SYNOPSIS 
Converts Pester XML output file into a simplified result set

.DESCRIPTION
Reads the .xml output (in NUNIT format) into memory and then parses out the results into a human readable form. 
Currently only desinged to used a single Describe in the pester script.

.PARAMETER XMLFile
File path to the pester -output .xml file

.PARAMETER Server
As we are running the same test against multiple servers this value lets you populate the server the test is ran against

.PARAMETER Summary
switch to say if you want a summary of Total tests, failures, errors. compared the standard breakdown of each test

.NOTES 
Author: Stephen.Bennett

.EXAMPLE   
Parse-PesterXML -XMLFile "C:\Temp\report.xml" -Server "Test" -Summary | ft

reads in the c:\temp\report.xml output from a pester test and creates an output (formatted as table)
    
#>
    param (
		[parameter(Mandatory = $true)]
        [string]$XMLFile,
        [string]$Server,
        [switch]$Summary = $false  
    )
    process 
    {
        if (!(Test-Path $XMLFile))
        {
            Write-Warning "Failed to find file you supplied.. pls try again"
        }
        
        ## read
        [xml]$xml = Get-Content $XMLFile
        
        if ($Summary -eq $false)
        {

            $results = $xml.'test-results'.'test-suite'.results.'test-suite'.results

            foreach ($r in $results.'test-case')
            {
                $out = [pscustomobject]@{
                    Server = $server
                    User = $xml.'test-results'.environment.user
                    DateTime = $xml.'test-results'.date
                    Context = $results = $xml.'test-results'.'test-suite'.results.'test-suite'.name
                    TestName = $r.description
                    TestResult = $r.result
                    TestTime = $r.time
                }
                $out
            }
        }
        else
        {
            $out = [pscustomobject]@{
                Server = $Server
                Total = $xml.'test-results'.total
                Failure = $xml.'test-results'.failures
                Error = $xml.'test-results'.errors
            }
            $out
        }
    } # process
} # function


