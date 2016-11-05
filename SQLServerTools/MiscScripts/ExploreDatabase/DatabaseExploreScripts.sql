/*Listing 1: Basic server information*/

-- Server and instance name 
Select SERVERPROPERTY('MachineName') as [Server\Instance]; 
-- SQL Server Version 
Select @@VERSION as SQLServerVersion; 
-- SQL Server Instance 
Select @@ServiceName AS ServiceInstance;

-- Current Database 
Select DB_NAME() AS CurrentDB_Name; 


/*Listing 2: how long has your server been running since startup?*/

-- Note the tempdb system database is recreated every time the server restarts 
-- Thus this is one method to tell when the database server was last restarted 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        create_date AS ServerStarted ,
        DATEDIFF(s, create_date, GETDATE()) / 86400.0 AS DaysRunning ,
        DATEDIFF(s, create_date, GETDATE()) AS SecondsRunnig
FROM    sys.databases
WHERE   name = 'tempdb'; 
GO

/*Listing 3: Linked Servers*/

EXEC sp_helpserver; 
--OR 
EXEC sp_linkedservers; 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        Server_Id AS LinkedServerID ,
        name AS LinkedServer ,
        Product ,
        Provider ,
        Data_Source ,
        Modify_Date
FROM    sys.servers
ORDER BY name; 
GO


/*Listing 4: Database Inventory*/

EXEC sp_helpdb; 
--OR 
EXEC sp_Databases; 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        name AS DBName ,
        recovery_model_Desc AS RecoveryModel ,
        Compatibility_level AS CompatiblityLevel ,
        create_date ,
        state_desc
FROM    sys.databases
ORDER BY Name; 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        d.name AS DBName ,
        create_date ,
        compatibility_level ,
        m.physical_name AS FileName
FROM    sys.databases d
        JOIN sys.master_files m ON d.database_id = m.database_id
WHERE   m.[type] = 0 -- data files only
ORDER BY d.name; 
GO

/*Listing 5: Last Database Backup */

SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        d.Name AS DBName ,
        MAX(b.backup_finish_date) AS LastBackupCompleted
FROM    sys.databases d
        LEFT OUTER JOIN msdb..backupset b
                    ON b.database_name = d.name
                       AND b.[type] = 'D'
GROUP BY d.Name
ORDER BY d.Name; 


/*Listing 6: Physical file location for recent backups*/

SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        d.Name AS DBName ,
        b.Backup_finish_date ,
        bmf.Physical_Device_name
FROM    sys.databases d
        INNER JOIN msdb..backupset b ON b.database_name = d.name
                                        AND b.[type] = 'D'
        INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id
ORDER BY d.NAME ,
        b.Backup_finish_date DESC; 
GO

/*Listing 7: Active connections by database*/

-- Similar information can be derived from sp_who 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME(database_id) AS DatabaseName ,
        COUNT(database_id) AS Connections ,
        Login_name AS LoginName ,
        MIN(Login_Time) AS Login_Time ,
        MIN(COALESCE(last_request_end_time, last_request_start_time)) AS Last_Batch
FROM    sys.dm_exec_sessions
WHERE   database_id > 0
        AND DB_NAME(database_id) NOT IN ( 'master', 'msdb' )
GROUP BY database_id ,
        login_name
ORDER BY DatabaseName;

/*Listing 8: Listing out all user-defined tables in a database*/

-- In this example U is for tables. Try swapping in one of the many other types. 
USE MyDatabase;
GO
SELECT  *
FROM    sys.objects
WHERE   [type] = 'U'; 


/*Listing 9: Physical file location of the current database. */

EXEC sp_Helpfile; 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME() AS DB_Name ,
        File_id ,
        Type_desc ,
        Name ,
        LEFT(Physical_Name, 1) AS Drive ,
        Physical_Name ,
        RIGHT(physical_name, 3) AS Ext ,
        Size ,
        Growth
FROM    sys.database_files
ORDER BY File_id; 
GO




/*Listing 10: Exploring table details*/
EXEC sp_tables; -- Note this method returns both table and views. 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        TABLE_CATALOG ,
        TABLE_SCHEMA ,
        TABLE_NAME
FROM    INFORMATION_SCHEMA.TABLES
WHERE   TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME ;
--OR
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS 'TableName' ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.Type = 'U' -- User table 
ORDER BY o.name;
--OR 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        t.Name AS TableName,
        t.[Type],
        t.create_date
FROM    sys.tables t
ORDER BY t.Name;
GO

/*Listing 11: A script to generate a script to return row counts for all tables*/
SELECT  'Select ''' + DB_NAME() + '.' + SCHEMA_NAME(SCHEMA_ID) + '.'
        + LEFT(o.name, 128) + ''' as DBName, count(*) as Count From ' + o.name
        + ';' AS ' Script generator to get counts for all tables'
FROM    sys.objects o
WHERE   o.[type] = 'U'
ORDER BY o.name;
GO


/*Listing 12: Using sp_msforeachtable to return row counts for all tables*/

CREATE TABLE #rowcount
    ( Tablename VARCHAR(128) ,
      Rowcnt INT ); 
EXEC sp_MSforeachtable 'insert into #rowcount select ''?'', count(*) from ?' 
SELECT  *
FROM    #rowcount
ORDER BY Tablename ,
        Rowcnt; 
DROP TABLE #rowcount;
GO


/*Listing 13: Return table row counts from the index or table partition*/
-- A faster way to get table row counts. 
-- Hint: get it from an index, not the table.
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(p.object_id) AS SchemaName ,
        OBJECT_NAME(p.object_id) AS TableName ,
        i.Type_Desc ,
        i.Name AS IndexUsedForCounts ,
        SUM(p.Rows) AS Rows
FROM    sys.partitions p
        JOIN sys.indexes i ON i.object_id = p.object_id
                              AND i.index_id = p.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' ) -- This is key (1 index per table) 
        AND OBJECT_SCHEMA_NAME(p.object_id) <> 'sys'
GROUP BY p.object_id ,
        i.type_desc ,
        i.Name
ORDER BY SchemaName ,
        TableName; 

-- OR 
-- Similar method to get row counts, but this uses DMV dm_db_partition_stats 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(ddps.object_id) AS SchemaName ,
        OBJECT_NAME(ddps.object_id) AS TableName ,
        i.Type_Desc ,
        i.Name AS IndexUsedForCounts ,
        SUM(ddps.row_count) AS Rows
FROM    sys.dm_db_partition_stats ddps
        JOIN sys.indexes i ON i.object_id = ddps.object_id
                              AND i.index_id = ddps.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' ) -- This is key (1 index per table) 
        AND OBJECT_SCHEMA_NAME(ddps.object_id) <> 'sys'
GROUP BY ddps.object_id ,
        i.type_desc ,
        i.Name
ORDER BY SchemaName ,
        TableName;
GO

/*Listing 14: Finding heaps*/

-- Heap tables (Method 1) 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        t.Name AS HeapTable ,
        t.Create_Date
FROM    sys.tables t
        INNER JOIN sys.indexes i ON t.object_id = i.object_id
                                    AND i.type_desc = 'HEAP'
ORDER BY t.Name 
--OR 
-- Heap tables (Method 2) 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        t.Name AS HeapTable ,
        t.Create_Date
FROM    sys.tables t
WHERE   OBJECTPROPERTY(OBJECT_ID, 'TableHasClustIndex') = 0
ORDER BY t.Name; 
--OR 
-- Heap tables (Method 3) also provides row counts 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(ddps.object_id) AS SchemaName ,
        OBJECT_NAME(ddps.object_id) AS TableName ,
        i.Type_Desc ,
        SUM(ddps.row_count) AS Rows
FROM    sys.dm_db_partition_stats AS ddps
        JOIN sys.indexes i ON i.object_id = ddps.object_id
                              AND i.index_id = ddps.index_id
WHERE   i.type_desc = 'HEAP'
        AND OBJECT_SCHEMA_NAME(ddps.object_id) <> 'sys'
GROUP BY ddps.object_id ,
        i.type_desc
ORDER BY TableName; 
GO

/*Listing 15: Read and write activity for all tables referenced since the last server restart, in a database*/

-- Table Reads and Writes 
-- Heap tables out of scope for this query. Heaps do not have indexes. 
-- Only lists tables referenced since the last server restart 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_NAME(ddius.object_id) AS TableName ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups) AS Reads ,
        SUM(ddius.user_updates) AS Writes ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups
            + ddius.user_updates) AS [Reads&Writes] ,
        ( SELECT    DATEDIFF(s, create_date, GETDATE()) / 86400.0
          FROM      master.sys.databases
          WHERE     name = 'tempdb'
        ) AS SampleDays ,
        ( SELECT    DATEDIFF(s, create_date, GETDATE()) AS SecoundsRunnig
          FROM      master.sys.databases
          WHERE     name = 'tempdb'
        ) AS SampleSeconds
FROM    sys.dm_db_index_usage_stats ddius
        INNER JOIN sys.indexes i ON ddius.object_id = i.object_id
                                     AND i.index_id = ddius.index_id
WHERE   OBJECTPROPERTY(ddius.object_id, 'IsUserTable') = 1
        AND ddius.database_id = DB_ID()
GROUP BY OBJECT_NAME(ddius.object_id)
ORDER BY [Reads&Writes] DESC;
GO


/*Listing 16: Read and write activity for all tables referenced since the last server restart, in all databases*/
-- Table Reads and Writes 
-- Heap tables out of scope for this query. Heaps do not have indexes. 
-- Only lists tables referenced since the last server restart 
-- This query uses a cursor to identify all the user databases on the server 
-- Consolidates individual database results into a report, using a temp table. 
DECLARE DBNameCursor CURSOR
FOR
    SELECT  Name
    FROM    sys.databases
    WHERE   Name NOT IN ( 'master', 'model', 'msdb', 'tempdb',
                            'distribution' )
    ORDER BY Name; 
DECLARE @DBName NVARCHAR(128) 
DECLARE @cmd VARCHAR(4000) 
IF OBJECT_ID(N'tempdb..TempResults') IS NOT NULL
    BEGIN 
        DROP TABLE tempdb..TempResults 
    END 
CREATE TABLE tempdb..TempResults
    (
      ServerName NVARCHAR(128) ,
      DBName NVARCHAR(128) ,
      TableName NVARCHAR(128) ,
      Reads INT ,
      Writes INT ,
      ReadsWrites INT ,
      SampleDays DECIMAL(18, 8) ,
      SampleSeconds INT
    ) 
OPEN DBNameCursor 
FETCH NEXT FROM DBNameCursor INTO @DBName 
WHILE @@fetch_status = 0
    BEGIN 
---------------------------------------------------- 
-- Print @DBName 
        SELECT  @cmd = 'Use ' + @DBName + '; ' 
        SELECT  @cmd = @cmd + ' Insert Into tempdb..TempResults 
SELECT SERVERPROPERTY(''MachineName'') AS ServerName, 
DB_NAME() AS DBName, 
object_name(ddius.object_id) AS TableName , 
SUM(ddius.user_seeks 
+ ddius.user_scans 
+ ddius.user_lookups) AS Reads, 
SUM(ddius.user_updates) as Writes, 
SUM(ddius.user_seeks 
+ ddius.user_scans 
+ ddius.user_lookups 
+ ddius.user_updates) as ReadsWrites, 
(SELECT datediff(s,create_date, GETDATE()) / 86400.0 
FROM sys.databases WHERE name = ''tempdb'') AS SampleDays, 
(SELECT datediff(s,create_date, GETDATE()) 
FROM sys.databases WHERE name = ''tempdb'') as SampleSeconds 
FROM sys.dm_db_index_usage_stats ddius 
INNER JOIN sys.indexes i
ON ddius.object_id = i.object_id 
AND i.index_id = ddius.index_id 
WHERE objectproperty(ddius.object_id,''IsUserTable'') = 1 --True 
AND ddius.database_id = db_id() 
GROUP BY object_name(ddius.object_id) 
ORDER BY ReadsWrites DESC;' 
--PRINT @cmd 
        EXECUTE (@cmd) 
----------------------------------------------------- 
        FETCH NEXT FROM DBNameCursor INTO @DBName 
    END 
CLOSE DBNameCursor 
DEALLOCATE DBNameCursor 
SELECT  *
FROM    tempdb..TempResults
ORDER BY DBName ,
        TableName; 
--DROP TABLE tempdb..TempResults; 
GO

/*Listing 17: Exploring views*/
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS ViewName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'V' -- View 
ORDER BY o.NAME 

--OR 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        Name AS ViewName ,
        create_date
FROM    sys.Views
ORDER BY Name 
--OR
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        TABLE_CATALOG ,
        TABLE_SCHEMA ,
        TABLE_NAME ,
        TABLE_TYPE
FROM    INFORMATION_SCHEMA.TABLES
WHERE   TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME 
--OR 
-- View details (Show the CREATE VIEW Code) 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'ViewName' ,
        o.Type ,
        o.create_date ,
        sm.[DEFINITION] AS 'View script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.Type = 'V' -- View 
ORDER BY o.NAME;
GO


/*Listing 18: Exploring synonyms*/
-- which synonyms exist?
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS ViewName ,
        o.Type ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'SN' -- Synonym 
ORDER BY o.NAME;
--OR 
-- synonymn details 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        s.name AS synonyms ,
        s.create_date ,
        s.base_object_name
FROM    sys.synonyms s
ORDER BY s.name;
GO

/*Listing 19: Exploring stored procedures*/
-- Stored Procedures 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS StoredProcedureName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'P' -- Stored Procedures 
ORDER BY o.name
--OR 
-- Stored Procedure details 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'ViewName' ,
        o.[type] ,
        o.Create_date ,
        sm.[definition] AS 'Stored Procedure script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.object_id
WHERE   o.[type] = 'P' -- Stored Procedures 
        -- AND sm.[definition] LIKE '%insert%'
        -- AND sm.[definition] LIKE '%update%'
        -- AND sm.[definition] LIKE '%delete%'
        -- AND sm.[definition] LIKE '%tablename%'
ORDER BY o.name;
GO


/*Listing 20: Exploring functions*/
-- Functions 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'Functions' ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.Type = 'FN' -- Function 
ORDER BY o.NAME;
--OR 
-- Function details 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'FunctionName' ,
        o.[Type] ,
        o.create_date ,
        sm.[DEFINITION] AS 'Function script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.[Type] = 'FN' -- Function 
ORDER BY o.NAME;
GO

/*Listing 21: Exploring triggers*/
-- Table Triggers 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        parent.name AS TableName ,
        o.name AS TriggerName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent ON o.parent_object_id = parent.object_id
WHERE   o.Type = 'TR' -- Triggers 
ORDER BY parent.name ,
        o.NAME 
--OR 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        Parent_id ,
        name AS TriggerName ,
        create_date
FROM    sys.triggers
WHERE   parent_class = 1
ORDER BY name;
--OR 
-- Trigger Details 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        OBJECT_NAME(Parent_object_id) AS TableName ,
        o.name AS 'TriggerName' ,
        o.Type ,
        o.create_date ,
        sm.[DEFINITION] AS 'Trigger script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.Type = 'TR' -- Triggers 
ORDER BY o.NAME;
GO

/*Listing 22: Exploring CHECK constraints*/
-- Check Constraints 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        parent.name AS 'TableName' ,
        o.name AS 'Constraints' ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent
               ON o.parent_object_id = parent.object_id
WHERE   o.Type = 'C' -- Check Constraints 
ORDER BY parent.name ,
        o.name 
--OR 
--CHECK constriant definitions
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName ,
        OBJECT_NAME(parent_object_id) AS TableName ,
        parent_column_id AS Column_NBR ,
        Name AS CheckConstraintName ,
        type ,
        type_desc ,
        create_date ,
        OBJECT_DEFINITION(object_id) AS CheckConstraintDefinition
FROM    sys.Check_constraints
ORDER BY TableName ,
        SchemaName ,
        Column_NBR 
GO


/*Listing 23: Exploring columns and their data types*/
-- Table Columns 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME() AS DBName ,
        isc.Table_Name AS TableName ,
        isc.Table_Schema AS SchemaName ,
        Ordinal_Position AS Ord ,
        Column_Name ,
        Data_Type ,
        Numeric_Precision AS Prec ,
        Numeric_Scale AS Scale ,
        Character_Maximum_Length AS LEN , -- -1 means MAX like Varchar(MAX) 
        Is_Nullable ,
        Column_Default ,
        Table_Type
FROM    INFORMATION_SCHEMA.COLUMNS isc
        INNER JOIN information_schema.tables ist
              ON isc.table_name = ist.table_name 
--      WHERE Table_Type = 'BASE TABLE' -- 'Base Table' or 'View' 
ORDER BY DBName ,
        TableName ,
        SchemaName ,
        Ordinal_position; 

-- Summary of Column names and usage counts 
-- Watch for column names with different data types or different lengths 
SELECT  SERVERPROPERTY('MachineName') AS Server ,
        DB_NAME() AS DBName ,
        Column_Name ,
        Data_Type ,
        Numeric_Precision AS Prec ,
        Numeric_Scale AS Scale ,
        Character_Maximum_Length ,
        COUNT(*) AS Count
FROM    information_schema.columns isc
        INNER JOIN information_schema.tables ist
               ON isc.table_name = ist.table_name
WHERE   Table_type = 'BASE TABLE'
GROUP BY Column_Name ,
        Data_Type ,
        Numeric_Precision ,
        Numeric_Scale ,
        Character_Maximum_Length;

-- Summary of data types 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        Data_Type ,
        Numeric_Precision AS Prec ,
        Numeric_Scale AS Scale ,
        Character_Maximum_Length AS [Length] ,
        COUNT(*) AS COUNT
FROM    information_schema.columns isc
        INNER JOIN information_schema.tables ist
               ON isc.table_name = ist.table_name
WHERE   Table_type = 'BASE TABLE'
GROUP BY Data_Type ,
        Numeric_Precision ,
        Numeric_Scale ,
        Character_Maximum_Length
ORDER BY Data_Type ,
        Numeric_Precision ,
        Numeric_Scale ,
        Character_Maximum_Length 

-- Large object data types or Binary Large Objects(BLOBs) 
-- Note if you are using Enterprise edition, these tables can't rebuild indexes "Online" 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        isc.Table_Name ,
        Ordinal_Position AS Ord ,
        Column_Name ,
        Data_Type AS BLOB_Data_Type ,
        Numeric_Precision AS Prec ,
        Numeric_Scale AS Scale ,
        Character_Maximum_Length AS [Length]
FROM    information_schema.columns isc
        INNER JOIN information_schema.tables ist
               ON isc.table_name = ist.table_name
WHERE   Table_type = 'BASE TABLE'
        AND ( Data_Type IN ( 'text', 'ntext', 'image', 'XML' )
              OR ( Data_Type IN ( 'varchar', 'nvarchar', 'varbinary' )
                   AND Character_Maximum_Length = -1
                 )
            ) -- varchar(max), nvarchar(max), varbinary(max) 
ORDER BY isc.Table_Name ,
        Ordinal_position;
GO

/*Listing 24: Exploring column default values*/
-- Table Defaults 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        parent.name AS TableName ,
        o.name AS Defaults ,
        o.[Type] ,
        o.Create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent
               ON o.parent_object_id = parent.object_id
WHERE   o.[Type] = 'D' -- Defaults 
ORDER BY parent.name ,
        o.NAME

--OR 
-- Column Defaults 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName ,
        OBJECT_NAME(parent_object_id) AS TableName ,
        parent_column_id AS Column_NBR ,
        Name AS DefaultName ,
        [type] ,
        type_desc ,
        create_date ,
        OBJECT_DEFINITION(object_id) AS Defaults
FROM    sys.default_constraints
ORDER BY TableName ,
        Column_NBR 
--OR 
-- Column Defaults 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        OBJECT_SCHEMA_NAME(t.object_id) AS SchemaName ,
        t.Name AS TableName ,
        c.Column_ID AS Ord ,
        c.Name AS Column_Name ,
        OBJECT_NAME(default_object_id) AS DefaultName ,
        OBJECT_DEFINITION(default_object_id) AS Defaults
FROM    sys.Tables t
        INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE   default_object_id <> 0
ORDER BY TableName ,
        SchemaName ,
        c.Column_ID 
GO

/*Listing 25: Exploring computed columns*/
-- Computed columns 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(object_id) AS SchemaName ,
        OBJECT_NAME(object_id) AS Tablename ,
        Column_id ,
        Name AS Computed_Column ,
        [Definition] ,
        is_persisted
FROM    sys.computed_columns
ORDER BY SchemaName ,
        Tablename ,
        [Definition]; 
--Or 
-- Computed Columns 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(t.object_id) AS SchemaName,
        t.Name AS TableName ,
        c.Column_ID AS Ord ,
        c.Name AS Computed_Column
FROM    sys.Tables t
        INNER JOIN sys.Columns c ON t.object_id = c.object_id
WHERE   is_computed = 1
ORDER BY t.Name ,
        SchemaName ,
        c.Column_ID 
GO

/*Listing 26: Exploring IDENTITY columns*/
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(object_id) AS SchemaName ,
        OBJECT_NAME(object_id) AS TableName ,
        Column_id ,
        Name AS IdentityColumn ,
        Seed_Value ,
        Last_Value
FROM    sys.identity_columns
ORDER BY SchemaName ,
        TableName ,
        Column_id; 
GO

/*Listing 27: Exploring existing indexes*/
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.Name AS TableName ,
        i.Name AS IndexName
FROM    sys.objects o
        INNER JOIN sys.indexes i ON o.object_id = i.object_id
WHERE   o.Type = 'U' -- User table 
        AND LEFT(i.Name, 1) <> '_' -- Remove hypothetical indexes 
ORDER BY o.NAME ,
        i.name; 
GO

/*Listing 28: Finding missing indexes*/
-- Missing Indexes DMV Suggestions 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DBName ,
        t.name AS 'Affected_table' ,
        ( LEN(ISNULL(ddmid.equality_columns, N'')
              + CASE WHEN ddmid.equality_columns IS NOT NULL
                          AND ddmid.inequality_columns IS NOT NULL THEN ','
                     ELSE ''
                END) - LEN(REPLACE(ISNULL(ddmid.equality_columns, N'')
                                   + CASE WHEN ddmid.equality_columns
                                                             IS NOT NULL
                                               AND ddmid.inequality_columns
                                                             IS NOT NULL
                                          THEN ','
                                          ELSE ''
                                     END, ',', '')) ) + 1 AS K ,
        COALESCE(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + COALESCE(ddmid.inequality_columns, '') AS Keys ,
        COALESCE(ddmid.included_columns, '') AS [include] ,
        'Create NonClustered Index IX_' + t.name + '_missing_'
        + CAST(ddmid.index_handle AS VARCHAR(20)) 
        + ' On ' + ddmid.[statement] COLLATE database_default
        + ' (' + ISNULL(ddmid.equality_columns, '')
        + CASE WHEN ddmid.equality_columns IS NOT NULL
                    AND ddmid.inequality_columns IS NOT NULL THEN ','
               ELSE ''
          END + ISNULL(ddmid.inequality_columns, '') + ')'
        + ISNULL(' Include (' + ddmid.included_columns + ');', ';')
                                                  AS sql_statement ,
        ddmigs.user_seeks ,
        ddmigs.user_scans ,
        CAST(( ddmigs.user_seeks + ddmigs.user_scans )
        * ddmigs.avg_user_impact AS BIGINT) AS 'est_impact' ,
        avg_user_impact ,
        ddmigs.last_user_seek ,
        ( SELECT    DATEDIFF(Second, create_date, GETDATE()) Seconds
          FROM      sys.databases
          WHERE     name = 'tempdb'
        ) SecondsUptime 
-- Select * 
FROM    sys.dm_db_missing_index_groups ddmig
        INNER JOIN sys.dm_db_missing_index_group_stats ddmigs
               ON ddmigs.group_handle = ddmig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details ddmid
               ON ddmig.index_handle = ddmid.index_handle
        INNER JOIN sys.tables t ON ddmid.OBJECT_ID = t.OBJECT_ID
WHERE   ddmid.database_id = DB_ID()
ORDER BY est_impact DESC;
GO

/*Listing 29: Exploring Foreign keys*/
-- Foreign Keys 
SELECT  SERVERPROPERTY('MachineName') AS ServerName ,
        DB_NAME() AS DB_Name ,
        parent.name AS 'TableName' ,
        o.name AS 'ForeignKey' ,
        o.[Type] ,
        o.Create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent ON o.parent_object_id = parent.object_id
WHERE   o.[Type] = 'F' -- Foreign Keys 
ORDER BY parent.name ,
        o.name 
--OR 
SELECT  f.name AS ForeignKey ,
        SCHEMA_NAME(f.SCHEMA_ID) AS SchemaName ,
        OBJECT_NAME(f.parent_object_id) AS TableName ,
        COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName ,
        SCHEMA_NAME(o.SCHEMA_ID) ReferenceSchemaName ,
        OBJECT_NAME(f.referenced_object_id) AS ReferenceTableName ,
        COL_NAME(fc.referenced_object_id, fc.referenced_column_id)
                                              AS ReferenceColumnName
FROM    sys.foreign_keys AS f
        INNER JOIN sys.foreign_key_columns AS fc
               ON f.OBJECT_ID = fc.constraint_object_id
        INNER JOIN sys.objects AS o ON o.OBJECT_ID = fc.referenced_object_id
ORDER BY TableName ,
        ReferenceTableName;
GO

/*Listing 30: Finding missing Foreign Key indexes*/

-- Foreign Keys missing indexes 
-- Note this script only works for creating single column indexes. 
-- Multiple FK columns are out of scope for this script. 
SELECT  DB_NAME() AS DBName ,
        rc.Constraint_Name AS FK_Constraint , 
-- rc.Constraint_Catalog AS FK_Database, 
-- rc.Constraint_Schema AS FKSch, 
        ccu.Table_Name AS FK_Table ,
        ccu.Column_Name AS FK_Column ,
        ccu2.Table_Name AS ParentTable ,
        ccu2.Column_Name AS ParentColumn ,
        I.Name AS IndexName ,
        CASE WHEN I.Name IS NULL
             THEN 'IF NOT EXISTS (SELECT * FROM sys.indexes
                                    WHERE object_id = OBJECT_ID(N'''
                  + RC.Constraint_Schema + '.' + ccu.Table_Name
                  + ''') AND name = N''IX_' + ccu.Table_Name + '_'
                  + ccu.Column_Name + ''') '
                  + 'CREATE NONCLUSTERED INDEX IX_' + ccu.Table_Name + '_'
                  + ccu.Column_Name + ' ON ' + rc.Constraint_Schema + '.'
                  + ccu.Table_Name + '( ' + ccu.Column_Name
                  + ' ASC ) WITH (PAD_INDEX = OFF, 
                                   STATISTICS_NORECOMPUTE = OFF,
                                   SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF,
                                   DROP_EXISTING = OFF, ONLINE = ON);'
             ELSE ''
        END AS SQL
FROM    information_schema.referential_constraints RC
        JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
         ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
        JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu2
         ON rc.UNIQUE_CONSTRAINT_NAME = ccu2.CONSTRAINT_NAME
        LEFT JOIN sys.columns c ON ccu.Column_Name = C.name
                                AND ccu.Table_Name = OBJECT_NAME(C.OBJECT_ID)
        LEFT JOIN sys.index_columns ic ON C.OBJECT_ID = IC.OBJECT_ID
                                          AND c.column_id = ic.column_id
                                          AND index_column_id = 1
                                           -- index found has the foreign key
                                          --  as the first column 
        LEFT JOIN sys.indexes i ON IC.OBJECT_ID = i.OBJECT_ID
                                   AND ic.index_Id = i.index_Id
WHERE   I.name IS NULL
ORDER BY FK_table ,
        ParentTable ,
        ParentColumn; 
GO


/*Listing 31: sp_msdependencies help*/
EXEC sp_msdependencies '?' ; -- Displays Help 
GO

/*Listing 32: using sp_msdependencies to view all dependencies*/
EXEC sp_msdependencies NULL    -- List all database dependencies 
EXEC sp_msdependencies NULL, 3 -- List table dependencies 
GO

/*Listing 33: using sp_msdependencies to view objects that depend on a table (first level only)*/
-- sp_MSdependencies sp_MSdependencies — First level only 
-- Objects that are dependent on the specified object 
EXEC sp_MSdependencies N'[Sales].[Customer]',null, 1315327 -- Change Table Name 
GO

/*Listing 34: Using sp_msdependencies to view objects on which a table depends*/
-- sp_MSdependencies - All levels 
-- Objects that are dependent on the specified object 
EXEC sp_MSdependencies N'[Sales].[Customer]', NULL, 266751 -- Change Table Name 
GO

/*Listing 35: using sp_msdependencies to view objects that depend on a table (all levels)*/
-- Objects that the specified object is dependent on 
EXEC sp_MSdependencies N'[Sales].[Customer]', null, 1053183 -- Change Table 
GO


/*Listing 36: Using sp_msdependencies to view only table dependencies*/
CREATE TABLE #TempTable1
    (
      Type INT ,
      ObjName VARCHAR(256) ,
      Owner VARCHAR(25) ,
      Sequence INT
    ); 
INSERT  INTO #TempTable1
        EXEC sp_MSdependencies NULL 
SELECT  *
FROM    #TempTable1
WHERE   Type = 8 --Tables 
ORDER BY Sequence ,
        ObjName 
DROP TABLE #TempTable1; 
GO

/*Listing 37: Using catalog views to view dependencies*/
--Independent tables
SELECT  [Name] AS InDependentTables
FROM    [sys].[tables]
WHERE   [object_id] NOT IN ( SELECT [referenced_object_id]
                             FROM   [sys].[foreign_key_columns] ) -- Check for parents
        AND [object_id] NOT IN ( SELECT [parent_object_id]
                                 FROM   [sys].[foreign_key_columns] ) -- Check for Dependents
ORDER BY [Name]

-- Tables with dependencies.
SELECT DISTINCT
        OBJECT_NAME([referenced_object_id]) AS ParentTable ,
        OBJECT_NAME([parent_object_id]) AS DependentTable ,
        OBJECT_NAME([constraint_object_id]) AS ForeignKeyName
FROM    [sys].[foreign_key_columns]
ORDER BY ParentTable ,
        DependentTable

-- Top level of the pyramid tables. Tables with no parents.
SELECT DISTINCT
        OBJECT_NAME([referenced_object_id]) AS TablesWithNoParent
FROM    [sys].[foreign_key_columns]
WHERE   [referenced_object_id] NOT IN ( SELECT  [parent_object_id]
                                        FROM    [sys].[foreign_key_columns] )
ORDER BY 1

-- Bottom level of the pyramid tables. 
-- Tables with no dependents. (These are the leaves on a tree.)
SELECT DISTINCT
        OBJECT_NAME([parent_object_id]) AS TablesWithNoDependents
FROM    [sys].[foreign_key_columns]
WHERE   [parent_object_id] NOT IN ( SELECT  [referenced_object_id]
                                    FROM    [sys].[foreign_key_columns] )
ORDER BY 1

-- Tables with both parents and dependents. (Tables in the middle of the hierarchy)
SELECT DISTINCT
        OBJECT_NAME([referenced_object_id]) AS MiddleTables
FROM    [sys].[foreign_key_columns]
WHERE   [referenced_object_id] IN ( SELECT  [parent_object_id]
                                    FROM    [sys].[foreign_key_columns] )
        AND [parent_object_id] NOT IN ( SELECT  [referenced_object_id]
                                        FROM    [sys].[foreign_key_columns] )
ORDER BY 1;

-- in rare cases, you might find a self-referencing dependent table.
-- Recursive (self) referencing table dependencies. 
SELECT DISTINCT
        OBJECT_NAME([referenced_object_id]) AS ParentTable ,
        OBJECT_NAME([parent_object_id]) AS ChildTable ,
        OBJECT_NAME([constraint_object_id]) AS ForeignKeyName
FROM    [sys].[foreign_key_columns]
WHERE   [referenced_object_id] = [parent_object_id]
ORDER BY 1 ,
        2;
GO

/*Listing 38: Using catalog views and a CTE to view dependencies*/
-- How to find the hierarchical dependencies
-- Solve recursive queries using Common Table Expressions (CTE)
WITH    TableHierarchy ( ParentTable, DependentTable, [Level] )
          AS (
-- Anchor member definition (First level group to start the process)
               SELECT DISTINCT
                        CAST(NULL AS INT) AS ParentTable ,
                        e.[referenced_object_id] AS DependentTable ,
                        0 AS [Level]
               FROM     [sys].[foreign_key_columns] AS e
               WHERE    e.[referenced_object_id] NOT IN (
                        SELECT  [parent_object_id]
                        FROM    [sys].[foreign_key_columns] )
-- Add filter dependents of only one parent table
-- AND Object_Name(e.[referenced_object_id]) = 'User'
               UNION ALL
-- Recursive member definition (Find all the layers of dependents)
               SELECT --Distinct
                        e.[referenced_object_id] AS ParentTable ,
                        e.[parent_object_id] AS DependentTable ,
                        [Level] + 1
               FROM     [sys].[foreign_key_columns] AS e
                        INNER JOIN TableHierarchy AS d ON ( e.[referenced_object_id] ) = d.DependentTable
             )
    -- Statement that executes the CTE
SELECT DISTINCT
        OBJECT_NAME(ParentTable) AS ParentTable ,
        OBJECT_NAME(DependentTable) AS DependentTable ,
        [Level]
FROM    TableHierarchy
ORDER BY [Level] ,
        ParentTable ,
        DependentTable;
