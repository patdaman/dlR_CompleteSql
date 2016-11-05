

-- =============================================
-- Author:		RP
-- Create date: 11/04/2015
-- Description: Create single view for all QuarterlyReports tables
-- Input is: database name from database containing the tables
-- prefix used in all tables to union (ie. QuarterlyReport_*)
-- Name of new view to create that unions all the tables
-- =============================================

CREATE PROCEDURE [dbo].[usp_CreateUnionView]
	@sDatabase nvarchar(100)
	,@sTablePrefix nvarchar(100)
	,@sViewName nvarchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @sDatabase nvarchar(100),@sTablePrefix nvarchar(100),@sViewName nvarchar(100)
	--	SET @sDatabase = N'SGNLQuarterlyReports'
	--	SET @sTablePrefix = N'QuarterlySnapshot'
	--	SET @sViewName = N'vi_SGNLUnion'

	--
	-- Select all tables in database with prefix
	--
	DECLARE @sDSQL0 VARCHAR(MAX)
	DECLARE @Tables TABLE 
	(
		TABLE_SCHEMA VARCHAR(100),
		TABLE_NAME VARCHAR(100)
	)
	SET @sDSQL0 = 	'SELECT TABLE_SCHEMA, TABLE_NAME  FROM '+ @sDatabase +'.information_schema.tables'+ CHAR(13) +
	'WHERE TABLE_NAME LIKE ''' + @sTablePrefix +'%'''+ CHAR(13) +
	'ORDER BY TABLE_NAME'+ CHAR(13) 

	INSERT INTO @Tables (TABLE_SCHEMA ,TABLE_NAME)
	EXEC (@sDSQL0)

	-- 
	-- Begin cursor to loop through all QuarterlyReport tables in the database
	-- 
	DECLARE @sSchemaAndTableName VARCHAR(300)
	DECLARE @sDSQL1 VARCHAR(20)
	DECLARE @sDSQL2 VARCHAR(MAX)

	SET @sDSQL1 = 'CREATE'
	IF EXISTS (SELECT TOP 1 1 FROM sys.views WHERE name = @sViewName)
	BEGIN
		SET @sDSQL1 = 'ALTER'
	END

	SET @sDSQL2 = 
		@sDSQL1 + ' VIEW [dbo].'+@sViewName+ CHAR(13) +
		'AS'+ CHAR(13) 

	DECLARE cTableList CURSOR FOR
	SELECT (TABLE_SCHEMA+'.'+TABLE_NAME) FROM @Tables 

	OPEN cTableList

	FETCH NEXT FROM cTableList INTO @sSchemaAndTableName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sDSQL2 = @sDSQL2 + 'SELECT * FROM ' + @sDatabase +  '.' + @sSchemaAndTableName + CHAR(13) + ' UNION ALL '
	FETCH NEXT FROM cTableList INTO @sSchemaAndTableName
	END

	CLOSE cTableList
	DEALLOCATE cTableList

	-- Remove the last UNION ALL
	IF LEN(@sDSQL2) > 11 SET @sDSQL2 = LEFT(@sDSQL2,LEN(@sDSQL2) - 11)

	--
	-- Create View from joined tables (alter view if it exists)
	--
	EXEC (@sDSQL2)
END