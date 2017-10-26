<#

    Elasticseach with Powershell by Example

        Elasticsearch health
        Index 


#>
##########################################################################################################
## Elasticsearch health
##########################################################################################################

## return summary of server
Invoke-WebRequest -Method get -Uri  "http://elasticsearch.creator.co.uk:9200"

# cluster health
Invoke-WebRequest -Method get -Uri  "http://elasticsearch.creator.co.uk:9200/_cluster/state?pretty"




##########################################################################################################
## Indexing
##########################################################################################################

# list all indexes on cluster
Invoke-WebRequest -Method Get -Uri "http://elasticsearch.creator.co.uk:9200/_cat/indices" 

# filter on indecies named like
GET /_cat/indices/twi*?v&s=index

# indecies health filter
get /_cat/indices?v&health=red

#learn about config of index / type
Invoke-WebRequest -Method get -Uri  "http://elasticsearch.creator.co.uk:9200/sqlserver/database" 

# Create a new Index 
Invoke-WebRequest -Method Put -Uri  "http://elasticsearch.creator.co.uk:9200/chef_handler" 

## count records in index type
Invoke-WebRequest -Method get -Uri  "http://elasticsearch.creator.co.uk:9200/sqldata/database/_count" 

# create mappings for type
put /sql
{
  "mappings":{
    "table": {
      "properties": {
        "Time" :{
          "type": "date"
        },
        "Server":{
          "type" : "text"
        },
        "Database" : {
          "type" : "text"
        },
        "Schema" :{
          "type" : "text"
        },
        "Table" : {
          "type" : "text"
        },
        "IndexSpaceUsed" :{
          "type" : "long"
        },
        "DataSpaceUsed" :{
          "type" : "long"
        },
        "RowCount" : {
          "type" : "long"
        }
      }
    }
  }
}





# Send data to Elasticsearch 
## This auto creates the Type and mappings for the type
$CustomObject = [pscustomobject]@{
      Time = Get-Date
      Server = "DEV-SQL-INT01"
      Cookbook = "install_sql"
      CookbookVersion = 1.0.0
      RanBy = "stephen.bennett"
}
$body = ConvertTo-Json $CustomObject -Compress
# using post as put needs Id
Invoke-RestMethod -Method Post `
     -Uri "http://localhost:9200/chef/cookbook" `
     -ContentType 'application/json' `
     -Body $body 


## input some data manually
Invoke-WebRequest -Method Post -UseBasicParsing `
    -Uri "http://localhost:9200/products/mobiles" `
    -Body '{"name" : "iphone", "version" : 6, "review" : "silly" }'

