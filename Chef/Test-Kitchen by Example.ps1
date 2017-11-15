<#

    Test-Kitchen by Example

#>
## list kitchen test state
kitchen list

## creates vm based on kitchen.yml
kitchen create

## applies cookbook to vm
kitchen converge

## kitchen verify runs tests from folder: 
kitchen verify

## test (destory -> create -> converge -> verify -> destory
kitchen test

## rdp - if not specificing in driver_config then it uses azure/P2ssw0rd for login/password
kitchen login

## example calling the vm 
kitchen exec -c '(Invoke-WebRequest -UseBasicParsing localhost).Content'
kitchen exec -c 'Get-Acl c:\inetpub\wwwroot\Default.htm | Format-List'
kitchen exec -c 'Get-DscLocalConfigurationManager | select -ExpandProperty "ConfigurationMode"'

## remove temp vm
kitchen test





