FUNCTION Get-SQLRoleMembers {

<#
.SYNOPSIS
Retrieves all members of the fixed SQL Server instance roles.
.DESCRIPTION
Get-SQLRoleMembers collects all members of a the standard SQL Server instance Rols 
.PARAMETER Instance
the SQL Server instance you wish to gather details from
.PARAMETER Role
The role you wish to list the members of options 'sysadmin', 'securityadmin', 'serveradmin', 'setupadmin', 'processadmin', 'diskadmin', 'dbcreator', 'bulkadmin'
.PARAMETER Output
Select how you wish to output the results either "Gridview" or "table"
.EXAMPLE
Get-SQLRoleMembers -Instance . -Role sysadmin -output table
.EXAMPLE
Get-SQLRoleMembers -Instance MySQLServer -Role securityadmin -output gridview
.NOTES
Created 07/09/15 Stephen Bennett 
.LINK
http://sqlnotesfromtheunderground.wordpress.com/
#>
 
        [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Instance,
        [Parameter(Mandatory=$true)]
        [ValidateSet('sysadmin', 'securityadmin', 'serveradmin', 'setupadmin', 'processadmin', 'diskadmin', 'dbcreator', 'bulkadmin')]
        [string]$Role,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Table', 'Gridview')]
        [string]$Output = 'Table'
    )


BEGIN{
function Get-ADNestedGroupMembers { 
<#  
.SYNOPSIS
Author: Piotr Lewandowski
Version: 1.01 (04.08.2015) - added displayname to the output, changed name to samaccountname in case of user objects.

.DESCRIPTION
Get nested group membership from a given group or a number of groups.

Function enumerates members of a given AD group recursively along with nesting level and parent group information. 
It also displays if each user account is enabled. 
When used with an -indent switch, it will display only names, but in a more user-friendly way (sort of a tree view) 
   
.EXAMPLE   
Get-ADNestedGroupMembers "MyGroup" | Export-CSV .\NedstedMembers.csv -NoTypeInformation

.EXAMPLE  
Get-ADGroup "MyGroup" | Get-ADNestedGroupMembers | ft -autosize
            
.EXAMPLE             
Get-ADNestedGroupMembers "MyGroup" -indent
 
#>

param ( 
[Parameter(ValuefromPipeline=$true,mandatory=$true)][String] $GroupName, 
[int] $nesting = -1, 
[int]$circular = $null, 
[switch]$indent 
) 
    function indent  
    { 
    Param($list) 
        foreach($line in $list) 
        { 
        $space = $null 
         
            for ($i=0;$i -lt $line.nesting;$i++) 
            { 
            $space += "    " 
            } 
            $line.name = "$space" + "$($line.name)"
        } 
      return $List 
    } 
     
$modules = get-module | select -expand name
    if ($modules -contains "ActiveDirectory") 
    { 
        $table = $null 
        $nestedmembers = $null 
        $adgroupname = $null     
        $nesting++   
        $ADGroupname = get-adgroup $groupname -properties memberof,members 
        $memberof = $adgroupname | select -expand memberof 
        write-verbose "Checking group: $($adgroupname.name)" 
        if ($adgroupname) 
        {  
            if ($circular) 
            { 
                $nestedMembers = Get-ADGroupMember -Identity $GroupName -recursive 
                $circular = $null 
            } 
            else 
            { 
                $nestedMembers = Get-ADGroupMember -Identity $GroupName | sort objectclass -Descending
                if (!($nestedmembers))
                {
                    $unknown = $ADGroupname | select -expand members
                    if ($unknown)
                    {
                        $nestedmembers=@()
                        foreach ($member in $unknown)
                        {
                        $nestedmembers += get-adobject $member
                        }
                    }

                }
            } 
 
            foreach ($nestedmember in $nestedmembers) 
            { 
                $Props = @{Type=$nestedmember.objectclass;Name=$nestedmember.name;DisplayName="";ParentGroup=$ADgroupname.name;Enabled="";Nesting=$nesting;DN=$nestedmember.distinguishedname;Comment=""} 
                 
                if ($nestedmember.objectclass -eq "user") 
                { 
                    $nestedADMember = get-aduser $nestedmember -properties enabled,displayname 
                    $table = new-object psobject -property $props 
                    $table.enabled = $nestedadmember.enabled
                    $table.name = $nestedadmember.samaccountname
                    $table.displayname = $nestedadmember.displayname
                    if ($indent) 
                    { 
                    indent $table | select @{N="Name";E={"$($_.name)  ($($_.displayname))"}}
                    } 
                    else 
                    { 
                    $table | select type,name,displayname,parentgroup,nesting,enabled,dn,comment 
                    } 
                } 
                elseif ($nestedmember.objectclass -eq "group") 
                {  
                    $table = new-object psobject -Property $props 
                     
                    if ($memberof -contains $nestedmember.distinguishedname) 
                    { 
                        $table.comment ="Circular membership" 
                        $circular = 1 
                    } 
                    if ($indent) 
                    { 
                    indent $table | select name,comment | %{
						
						if ($_.comment -ne "")
						{
						[console]::foregroundcolor = "red"
						write-output "$($_.name) (Circular Membership)"
						[console]::ResetColor()
						}
						else
						{
						[console]::foregroundcolor = "yellow"
						write-output "$($_.name)"
						[console]::ResetColor()
						}
                    }
					}
                    else 
                    { 
                    $table | select type,name,displayname,parentgroup,nesting,enabled,dn,comment 
                    } 
                    if ($indent) 
                    { 
                       Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent 
                    } 
                    else  
                    { 
                       Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular 
                    } 
              	                  
               } 
                else 
                { 
                    
                    if ($nestedmember)
                    {
                        $table = new-object psobject -property $props
                        if ($indent) 
                        { 
    	                    indent $table | select name 
                        } 
                        else 
                        { 
                        $table | select type,name,displayname,parentgroup,nesting,enabled,dn,comment    
                        } 
                     }
                } 
              
            } 
         } 
    } 
    else {Write-Warning "Active Directory module is not loaded"}        
}


IF (!(Get-Module -Name sqlps))
    {
        Push-Location
        Import-Module sqlps -DisableNameChecking
        Pop-Location 
    }

    $roleScript = switch ($Role)
        {
            "sysadmin" {"AND s.sysadmin = 1"}
            "securityadmin" {"AND s.securityadmin = 1"}
            "serveradmin" {"AND s.serveradmin = 1"}
            "setupadmin" {"AND s.setupadmin = 1"}
            "processadmin" {"AND s.processadmin = 1"}
            "diskadmin" {"AND s.diskadmin = 1"}
            "dbcreator" {"AND s.dbcreator = 1"}
            "bulkadmin" {"AND s.bulkadmin = 1"}
        }

$tsql = @'
SELECT  p.name AS [loginname] ,
        p.type_desc, is_disabled
FROM    sys.server_principals p
        JOIN sys.syslogins s ON p.sid = s.sid
WHERE   p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
        -- Logins that are not process logins
        AND p.name NOT LIKE '##%'

'@ + $roleScript
}

PROCESS {


try {
        $everything_ok = $true
        $tsqlResults = Invoke-Sqlcmd -ServerInstance $Instance -Query $tsql -ErrorAction Stop
}
catch{
        $everything_ok = $false
        write-host "Failed to connect to $Instance"
}

IF ($everything_ok){
# filter results to list out groups in the role
$ResultGroups = $tsqlResults | Where-Object {$_.type_desc -eq "WINDOWS_GROUP" -and $_.loginname -ne "NT SERVICE\SQLSERVERAGENT"} | Select-Object loginname
## list all other single users 
$resultssingles = $tsqlResults | Where-Object {$_.type_desc -ne "WINDOWS_GROUP"} | select loginname, type_desc, is_disabled

$recursiveGroups = $null 
ForEach ($windowsGroup in $ResultGroups){
    $a = $windowsGroup.loginname
    $a = $a.split('\')[-1]
    $group = Get-ADGroup $a | Get-ADNestedGroupMembers | select DisplayName, ParentGroup, Enabled
    $recursiveGroups += $group
}

## create final object 
$objectCollection=@()

## Add Single Uses to final Result
foreach ($user in $resultssingles){

    ## add columns for final object
    $object = New-Object PSObject
    Add-Member -InputObject $object -MemberType NoteProperty -Name Login -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Type -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Group -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Disabled -Value ""
    $object.Login = $user.loginname.split('\')[-1]
    $object.Type = $user.type_desc
    $object.Group = ""
    $object.Disabled = $user.is_disabled

     $objectCollection += $object
}
foreach ($login in $recursiveGroups){

    ## add columns for final object
    $object = New-Object PSObject
    Add-Member -InputObject $object -MemberType NoteProperty -Name Login -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Type -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Group -Value ""
    Add-Member -InputObject $object -MemberType NoteProperty -Name Disabled -Value ""
    $object.Login = $login.DisplayName
    $object.Type = "WINDOWS_GROUP"
    $object.Group = $login.ParentGroup
    if ($login.Enabled = "True"){
        $object.Disabled = "False"
    } else {
       $object.Disabled = "True" 
    }

     $objectCollection += $object
}
}

}

END {
    if ($Output -eq 'Table')
        {
            $objectCollection | ft -AutoSize -Wrap
        } 
    elseif ($output -eq 'GridView')
        {
            $objectCollection | Out-GridView
        }
    }

}
