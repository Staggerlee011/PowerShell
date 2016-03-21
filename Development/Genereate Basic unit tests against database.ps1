<#

Genereate Basic unit tests against database

#>
## Configure vars

$server = "LON-WS-066\r2"
$database = "Titan"

## Import SQLPS
IF (!(Get-Module -Name sqlps))
    {
        Push-Location
        Import-Module sqlps -DisableNameChecking
        Pop-Location
    }

## Create a test class for every object with name SCHEMA_OBJECT
$GetAllTablesQuery = "SELECT   s.name AS [SchemaName],
			o.name AS [ObjectName],
        s.name + '_' + o.name AS 'TestClass'
FROM    sys.objects AS o
JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE   type IN ('FN', 'SN', 'AF', 'PC', 'FN', 'FS', 'FT', 'IF', 'V', 'TR', 'X')
AND s.name <> 'tSQLt'

UNION ALL

SELECT  TABLE_SCHEMA AS [SchemaName] ,
        TABLE_NAME AS [ObjectName] ,
        TABLE_SCHEMA + '_' + TABLE_NAME AS 'TestClass'
FROM    INFORMATION_SCHEMA.TABLES
WHERE   TABLE_TYPE = 'BASE TABLE'
        AND TABLE_SCHEMA <> 'tSQLt'
ORDER BY TestClass"

$TablesInDb = invoke-sqlcmd -server $server -database $database -query $GetAllTablesQuery

ForEach ($Table in $TablesInDb)
    {
        
        # Create Test Class for each object (SCHEMA_OBJECT)

        $NewClass = $Table.TestClass
        $TestObject = $Table.SchemaName + "." + $Table.ObjectName
        $NewClassQuery = "EXEC tSQLt.NewTestClass  '$NewClass';"
        Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $NewClassQuery

        # Create a object exists test

        $NewTestQuery = "create PROCEDURE [$NewClass].[test Object Exists]
AS
    BEGIN

  --Assemble

  --Act

  --Assert
        EXEC tSQLt.AssertObjectExists @ObjectName = '$TestObject';
    END;"


       
       Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $NewTestQuery

    }