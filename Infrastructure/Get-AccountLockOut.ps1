function Get-AccountLockOut {
<#
.SYNOPSIS
Returns a MaxEvents number of lock events for a login

.DESCRIPTION
Gathers domain controller information and then looks at windows security events to find the username and event type matches. 
	
.PARAMETER UserName
User name to return information on

.PARAMETER MaxEvents
Default value is 10, but can be changed to any INT value

.NOTES
No support is avilable for this function 

.EXAMPLE
Get-AccountLockOut -UserName ‘firstname.surname’ -MaxEvents 11

Returns the last 11 lock out events for ‘firstname.surname’

#>	
    param (
        [string]$UserName,
        [int]$MaxEvents = 10

    )

    process 
    {
        ## Find the domain controller PDCe role
        $Pdce = (Get-AdDomain).PDCEmulator
        
        ## Build the parameters to pass to Get-WinEvent
        $GweParams = @{
             ‘Computername’ = $Pdce
             ‘LogName’ = ‘Security’
             ‘FilterXPath’ = "*[System[EventID=4740] and EventData[Data[@Name='TargetUserName']='$Username']]"
        }
        
        ## Query the security event log
        $Events = Get-WinEvent @GweParams -MaxEvents $MaxEvents
        
        ## results
        $output = @()
        foreach ($event in $Events)
        {
            $obj = New-Object psobject -Property @{
                Server = $event[0].Properties[1].Value;
                Time = $event.TimeCreated;
            }
            $output += $obj 
        } # forecah
        
        ## output
        $output
    } # process

} # function

