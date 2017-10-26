<#

    Chef with PowerShell By Example

        You will need to install the ChefDK This is a collection of commands including a powershell module)
            https://downloads.chef.io/chefdk#windows

#>
<#

    Basic configure

        Import module
        download chef 

#>


## load Chef module (This is what clicking on the Chef Development Kit
Import-Module C:\opscode\chefdk\modules\chef

get-command -Module chef 

## download chef lab starter kit (this sets up comms based on your login)
cd C:\git\internal_infra\ChefSB
## download ssl
knife ssl fetch


<#

    Chef DB

#>
<#

    GET EVERYTHING FROM EXISTING CHEF SERVER
#>
knife download cookbooks
knife download environments
knife download data_bags
knife download roles

<#
    COOKBOOK
#>
## create cookbook
chef generate cookbook elasticMonitoring

## list cookbooks (on server)
knife cookbook list

## upload cookbook
knife cookbook upload --all

## upload individual cookbook
knife cookbook upload lab-windows


## download a cookbook
knife download cookbook 


## delete a cookbook
knife cookbook delete lab-windows 0.1.1



knife cookbook delete COOKBOOK VERSION (options)
knife cookbook download COOKBOOK [VERSION] (options)
knife cookbook list (options)
knife cookbook metadata COOKBOOK (options)
knife cookbook metadata from FILE (options)
knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME] (options)
knife cookbook test [COOKBOOKS...] (options)
knife cookbook upload [COOKBOOKS...] (options)



<#
    ROLES
#>
## list roles on server
knife role list

## download a role 

## upload role (chefdk)
knife role from file C:\GIT\internal_infra\ChefSB\roles\lab-windows.rb


<#

    Bootstrapping Chef Nodes

#>
## list all clients 
knife node list

# linux 
knife bootstrap <SERVERNAME>    `
    --ssh-user stephenbennett   `
    --ssh-password              `
    --node-name <SERVERNAME>    `
    -- sudo                     `
    -- verbose

# windows 
## chef runs on ruby gems to check the needed gem is installed
gem list knife-windows

## update gem  (connects to http://rubygems.org)
gem update knife-windows

## install is done via winrm
winrm /quickconfig

## client needs winrm trustedhost to chef server
winrm g winrm/config/client

## if missing update with
winrm s winrm/config/client '@{TrustedHosts="<CHEFSERVERNAME>"}'


## install chef bootstrap on windows
knife bootstrap windows winrm <SERVERNAME>  `
    --winrm-user <username>                 `
    --winrm-password <password>             `
    --node-name <SERVERNAME>                



<#

    Apply Cookbooks (runlists) to client
    trigger chef client

#>
## LINUX MACHINE
chef-client

## windows machine
## may need to update $env:path check if opscode is listed
$env:path -split ";"

## update env:path
$env:path += ";C:\opscode\chef\bin"

## run on windows
chef-client.bat

# add role to node run_list (from checkdk)
knife node run_list add DEV-SQL-INT03 "role[lab-windows]"
