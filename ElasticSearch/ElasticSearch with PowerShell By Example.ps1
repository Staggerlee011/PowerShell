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










get _cat/indices?v&health=red


GET /_cat/indices/metricbeat-2017.*?v&s=index


GET /_cat/indices?v&s=docs.count:desc
put /sqlhistory
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


get sqldb/sqldb_size/_count


GET /_cat/indices?v&s=docs.count:desc

delete metricbeat-2017.09.30                                           
delete metricbeat-2017.09.29                                           
delete metricbeat-2017.10.04                                           
delete metricbeat-2017.10.01                                           
delete metricbeat-2017.10.03                                           
delete metricbeat-2017.10.05                                           
delete metricbeat-2017.10.02


get sql 

get _cluster/health

get _cluster/health?pretty

get _nodes?pretty

get 


get _cat/shards?h=index,shard,prirep,state,unassigned.reason| grep UNASSIGNED

get _cluster/allocation/explain?pretty

get _cluster/health?pretty=true

post _template/sqldb_template
{
  "template" : "sqldb-*",
  "aliases" : {
    "sqldb" : {}
  },
  "settings" : {
    "index" : {
      "number_of_shards" : 5,
      "number_of_replicas" : 0
    }
  },
  "mappings" : {
    "sqldb_size" : {
      "properties" : {
        "date" : {
          "type" : "date"
        },
        "server" : {
          "type" : "keyword"
        },
         "database" : {
          "type" : "keyword"
        },
        "logicalName" : {
          "type" : "keyword"
        },
        "fieldType" : {
          "type" : "keyword"
        },
        "usedSpace" : {
          "type" : "long"
        }
      }
    }
  }
}



PUT /_settings
{
    "index" : {
        "number_of_replicas" : 1
    }
}