-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-04
-- Description:	Search for entries in audit table 
--				Not made by CRUD updates
-- =============================================
CREATE PROCEDURE [dbo].[usp_SearchAuditTablesForInvalidUser] 
	-- Add the parameters for the stored procedure here
	@ValidUserPrefix varchar(100), 
	@ValidCommaSeparatedList varchar(max),
	@InvalidCommaSeparatedList varchar(max),
	@ValidSchemaCommaSeparatedList varchar(max),
	@InvalidSchemaCommaSeparatedList varchar(max),
	@ValidTableCommaSeparatedList varchar(max),
	@InvalidTableCommaSeparatedList varchar(max),
	@PrintQuery bit,
	@DeleteRows bit
AS
BEGIN --> 1
	SET NOCOUNT ON
	DECLARE @SQL nvarchar(max)
	DECLARE @AuditNameExtention varchar(128)
	DECLARE @ValidList varchar(max)
	DECLARE @InvalidList varchar(max)
	DECLARE @ValidSchemaList varchar(max)
	DECLARE @InvalidSchemaList varchar(max)
	DECLARE @ValidTableList varchar(max)
	DECLARE @InvalidTableList varchar(max)
	DECLARE @TABLE_NAME sysname
	DECLARE @TABLE_SCHEMA sysname
	DECLARE @CRLF char(2)
	DECLARE @User VARCHAR(100)
	DECLARE @Schema sysname
	DECLARE @Table sysname
	DECLARE @ValidUser VARCHAR(100)
	DECLARE @ColumnName sysname
	DECLARE @ColumnDefault sysname
	DECLARE @BlankColumns VARCHAR(MAX)
	DECLARE @PrintQueryText varchar(MAX)

	SET @InvalidList = COALESCE(@InvalidCommaSeparatedList, '')
	SET @InvalidList = REPLACE(@InvalidList, ' ', '')
	SET @ValidList = COALESCE(@ValidCommaSeparatedList, '')
	SET @ValidList = REPLACE(@ValidList, ' ', '')
	SET @InvalidSchemaList = COALESCE(@InvalidCommaSeparatedList, '')
	SET @InvalidSchemaList = REPLACE(@InvalidSchemaList, ' ', '')
	SET @validSchemaList = COALESCE(@ValidCommaSeparatedList, '')
	SET @validSchemaList = REPLACE(@validSchemaList, ' ', '')
	SET @InvalidTableList = COALESCE(@InvalidCommaSeparatedList, '')
	SET @InvalidTableList = REPLACE(@InvalidTableList, ' ', '')
	SET @validTableList = COALESCE(@ValidCommaSeparatedList, '')
	SET @validTableList = REPLACE(@validTableList, ' ', '')
	SET @ValidUserPrefix = COALESCE(@ValidUserPrefix, '!!**')
	SET @PrintQuery = COALESCE(@PrintQuery,0)
	SET @CRLF = Char(13) + Char(10)
	SET @AuditNameExtention = '_audit'
	-- ******************************************************************** --
	-- If you want to delete invalid users, you must comment out the next line
	--	(SET @DeleteRows = 0)
	-- ******************************************************************** --
	-- SET @DeleteRows = 0	
	SET @DeleteRows = COALESCE(@DeleteRows, 0)


IF @PrintQuery = 1
BEGIN
	SET @SQL = 
		'SET NOCOUNT ON' + @CRLF + 'DECLARE @SQL nvarchar(max)'+@CRLF+'DECLARE @AuditNameExtention varchar(128)'+@CRLF+'DECLARE @ValidList varchar(max)'+@CRLF+'DECLARE @InvalidList varchar(max)'+@CRLF+'DECLARE @ValidSchemaList varchar(max)'+@CRLF+'DECLARE @InvalidSchemaList varchar(max)'+@CRLF+'DECLARE @ValidTableList varchar(max)'+@CRLF+'DECLARE @InvalidTableList varchar(max)'+@CRLF+'DECLARE @TABLE_NAME sysname'+@CRLF+'DECLARE @TABLE_SCHEMA sysname'+@CRLF+'DECLARE @CRLF char(2)'+@CRLF+'DECLARE @User VARCHAR(100)'+@CRLF+'DECLARE @Schema sysname'+@CRLF+'DECLARE @Table sysname'+@CRLF+'DECLARE @ValidUser VARCHAR(100)'+@CRLF+'DECLARE @ColumnName sysname'+@CRLF+'DECLARE @BlankColumns VARCHAR(MAX)'+@CRLF+'DECLARE @PrintQueryText varchar(MAX)'+@CRLF+'SET @InvalidList = COALESCE(@InvalidCommaSeparatedList, '''')'+@CRLF+'SET @InvalidList = REPLACE(@InvalidList, '' '', '''')'+@CRLF+'SET @ValidList = COALESCE(@ValidCommaSeparatedList, '''')'+@CRLF+'SET @ValidList = REPLACE(@ValidList, '' '', '''')'+@CRLF+'SET @InvalidSchemaList = COALESCE(@InvalidCommaSeparatedList, '''')'+@CRLF+'SET @InvalidSchemaList = REPLACE(@InvalidSchemaList, '' '', '''')'+@CRLF+'SET @validSchemaList = COALESCE(@ValidCommaSeparatedList, '''')'+@CRLF+'SET @validSchemaList = REPLACE(@validSchemaList, '' '', '''')'+@CRLF+'SET @InvalidTableList = COALESCE(@InvalidCommaSeparatedList, '''')'+@CRLF+'SET @InvalidTableList = REPLACE(@InvalidTableList, '' '', '''')'+@CRLF+'SET @validTableList = COALESCE(@ValidCommaSeparatedList, '''')'+@CRLF+'SET @validTableList = REPLACE(@validTableList, '' '', '''')'+@CRLF+'SET @ValidUserPrefix = COALESCE(@ValidUserPrefix, ''!!**'')'+@CRLF+'SET @PrintQuery = COALESCE(@PrintQuery,0)'+@CRLF+'SET @CRLF = Char(13) + Char(10)'+@CRLF+'SET @AuditNameExtention = ''_audit'''+@CRLF+'-- ******************************************************************** --'+@CRLF+'-- If you want to delete invalid users, you must comment out the next line'+@CRLF+'--(SET @DeleteRows = 0)'+@CRLF+'-- ******************************************************************** --'+@CRLF+'-- SET @DeleteRows = 0'+@CRLF+'SET @DeleteRows = COALESCE(@DeleteRows, 0)'+@CRLF+@CRLF
	PRINT @SQL
	SET @SQL = 
		'IF OBJECT_ID(''tempdb..#InvalidSchema'') IS NOT NULL' + @CRLF + 'DROP TABLE #InvalidSchema' + @CRLF + 'CREATE TABLE #InvalidSchema (InvalidSchema VARCHAR(100))' + @CRLF + 'WHILE (LEN(@InvalidSchemaList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = ''''' + @CRLF + 'IF CHARINDEX('','',@InvalidSchemaList) > 0' + @CRLF + 'SET  @Schema = SUBSTRING(@InvalidSchemaList,0,CHARINDEX('','',@InvalidSchemaList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @Schema = @InvalidSchemaList' + @CRLF + 'SET @InvalidSchemaList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO #InvalidSchema (InvalidSchema) VALUES (@User)' + @CRLF + 'SET @InvalidList = REPLACE(@InvalidList,@User + '','' , '''')' + @CRLF + 'END' + @CRLF + 'IF OBJECT_ID(''tempdb..#ValidSchema'') IS NOT NULL' + @CRLF + 'DROP TABLE #ValidSchema' + @CRLF + 'CREATE TABLE #ValidSchema (ValidSchema VARCHAR(100))' + @CRLF + 'WHILE (LEN(@ValidList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = ''''' + @CRLF + 'IF CHARINDEX('','',@ValidSchemaList) > 0' + @CRLF + 'SET  @Schema = SUBSTRING(@ValidSchemaList,0,CHARINDEX('','',@ValidSchemaList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @Schema = @ValidSchemaList' + @CRLF + 'SET @ValidSchemaList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO #ValidSchema (ValidSchema) VALUES (@User)' + @CRLF + 'SET @ValidList = REPLACE(@ValidList,@User + '','' , '''')' + @CRLF + 'END' + @CRLF + 'IF OBJECT_ID(''tempdb..#InvalidTable'') IS NOT NULL' + @CRLF + 'DROP TABLE #InvalidTable' + @CRLF + 'CREATE TABLE #InvalidTable (InvalidTable VARCHAR(100))' + @CRLF + 'WHILE (LEN(@InvalidTableList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = ''''' + @CRLF + 'IF CHARINDEX('','',@InvalidTableList) > 0' + @CRLF + 'SET  @Table = SUBSTRING(@InvalidTableList,0,CHARINDEX('','',@InvalidTableList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @Table = @InvalidTableList' + @CRLF + 'SET @InvalidTableList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO #InvalidTable (InvalidTable) VALUES (@User)' + @CRLF + 'SET @InvalidList = REPLACE(@InvalidList,@User + '','' , '''')' + @CRLF + 'END' + @CRLF + 'IF OBJECT_ID(''tempdb..#ValidTable'') IS NOT NULL' + @CRLF + 'DROP TABLE #ValidTable' + @CRLF + 'CREATE TABLE #ValidTable (ValidTable VARCHAR(100))' + @CRLF + 'WHILE (LEN(@ValidList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = ''''' + @CRLF + 'IF CHARINDEX('','',@ValidTableList) > 0' + @CRLF + 'SET  @Table = SUBSTRING(@ValidTableList,0,CHARINDEX('','',@ValidTableList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @Table = @ValidTableList' + @CRLF + 'SET @ValidTableList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO #ValidTable (ValidTable) VALUES (@User)' + @CRLF + 'SET @ValidList = REPLACE(@ValidList,@User + '','' , '''')' + @CRLF + 'END' + @CRLF + 'IF OBJECT_ID(''tempdb..#InvalidTemp'') IS NOT NULL' + @CRLF + 'DROP TABLE #InvalidTemp' + @CRLF + 'CREATE TABLE #InvalidTemp (InvalidUser VARCHAR(100))' + @CRLF + 'WHILE (LEN(@InvalidList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = ''''' + @CRLF + 'IF CHARINDEX('','',@InvalidList) > 0' + @CRLF + 'SET  @User = SUBSTRING(@InvalidList,0,CHARINDEX('','',@InvalidList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @User = @InvalidList' + @CRLF + 'SET @InvalidList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO #InvalidTemp (InvalidUser) VALUES (@User)' + @CRLF + 'SET @InvalidList = REPLACE(@InvalidList,@User + '','' , '''')' + @CRLF + 'END' + @CRLF + 'IF OBJECT_ID(''tempdb..#ValidTemp'') IS NOT NULL' + @CRLF + 'DROP TABLE #ValidTemp' + @CRLF + 'CREATE TABLE #ValidTemp (ValidUser VARCHAR(100))' + @CRLF + 'WHILE (LEN(@ValidList) > 0)' + @CRLF + 'BEGIN' + @CRLF + 'SET @ValidUser = ''''' + @CRLF + 'IF CHARINDEX('','',@ValidList) > 0' + @CRLF + 'SET  @ValidUser = SUBSTRING(@ValidList,0,CHARINDEX('','',@ValidList))' + @CRLF + 'ELSE' + @CRLF + 'BEGIN' + @CRLF + 'SET @ValidUser = @ValidList' + @CRLF + 'SET @ValidList = ''''' + @CRLF + 'END' + @CRLF + 'INSERT INTO  #ValidTemp (ValidUser) VALUES (@ValidUser)' + @CRLF + 'SET @ValidList = REPLACE(@ValidList,@ValidUser + '','' , '''')' + @CRLF + 'END'
	PRINT @SQL
END

	IF OBJECT_ID('tempdb..#InvalidSchema') IS NOT NULL
		DROP TABLE #InvalidSchema
	CREATE TABLE #InvalidSchema (InvalidSchema VARCHAR(100))
	WHILE (LEN(@InvalidSchemaList) > 0)
	BEGIN
		SET @User = ''
		IF CHARINDEX(',',@InvalidSchemaList) > 0
			SET  @Schema = SUBSTRING(@InvalidSchemaList,0,CHARINDEX(',',@InvalidSchemaList))
	
		ELSE
		BEGIN
			SET @Schema = @InvalidSchemaList
			SET @InvalidSchemaList = ''
		END
	
		INSERT INTO #InvalidSchema (InvalidSchema) VALUES (@User)
		SET @InvalidList = REPLACE(@InvalidList,@User + ',' , '')
	END

	IF OBJECT_ID('tempdb..#ValidSchema') IS NOT NULL
		DROP TABLE #ValidSchema
	CREATE TABLE #ValidSchema (ValidSchema VARCHAR(100))
	WHILE (LEN(@ValidList) > 0)
	BEGIN
		SET @User = ''
		IF CHARINDEX(',',@ValidSchemaList) > 0
			SET  @Schema = SUBSTRING(@ValidSchemaList,0,CHARINDEX(',',@ValidSchemaList))
	
		ELSE
		BEGIN
			SET @Schema = @ValidSchemaList
			SET @ValidSchemaList = ''
		END
	
		INSERT INTO #ValidSchema (ValidSchema) VALUES (@User)
		SET @ValidList = REPLACE(@ValidList,@User + ',' , '')
	END

	IF OBJECT_ID('tempdb..#InvalidTable') IS NOT NULL
		DROP TABLE #InvalidTable
	CREATE TABLE #InvalidTable (InvalidTable VARCHAR(100))
	WHILE (LEN(@InvalidTableList) > 0)
	BEGIN
		SET @User = ''
		IF CHARINDEX(',',@InvalidTableList) > 0
			SET  @Table = SUBSTRING(@InvalidTableList,0,CHARINDEX(',',@InvalidTableList))
	
		ELSE
		BEGIN
			SET @Table = @InvalidTableList
			SET @InvalidTableList = ''
		END
	
		INSERT INTO #InvalidTable (InvalidTable) VALUES (@User)
		SET @InvalidList = REPLACE(@InvalidList,@User + ',' , '')
	END

	IF OBJECT_ID('tempdb..#ValidTable') IS NOT NULL
		DROP TABLE #ValidTable
	CREATE TABLE #ValidTable (ValidTable VARCHAR(100))
	WHILE (LEN(@ValidList) > 0)
	BEGIN
		SET @User = ''
		IF CHARINDEX(',',@ValidTableList) > 0
			SET  @Table = SUBSTRING(@ValidTableList,0,CHARINDEX(',',@ValidTableList))
	
		ELSE
		BEGIN
			SET @Table = @ValidTableList
			SET @ValidTableList = ''
		END
	
		INSERT INTO #ValidTable (ValidTable) VALUES (@User)
		SET @ValidList = REPLACE(@ValidList,@User + ',' , '')
	END

	IF OBJECT_ID('tempdb..#InvalidTemp') IS NOT NULL
		DROP TABLE #InvalidTemp
	CREATE TABLE #InvalidTemp (InvalidUser VARCHAR(100))
	WHILE (LEN(@InvalidList) > 0)
	BEGIN
		SET @User = ''
		IF CHARINDEX(',',@InvalidList) > 0
			SET  @User = SUBSTRING(@InvalidList,0,CHARINDEX(',',@InvalidList))
	
		ELSE
		BEGIN
			SET @User = @InvalidList
			SET @InvalidList = ''
		END
	
		INSERT INTO #InvalidTemp (InvalidUser) VALUES (@User)
		SET @InvalidList = REPLACE(@InvalidList,@User + ',' , '')
	END

	IF OBJECT_ID('tempdb..#ValidTemp') IS NOT NULL
		DROP TABLE #ValidTemp	
	CREATE TABLE #ValidTemp (ValidUser VARCHAR(100))
	WHILE (LEN(@ValidList) > 0)
	BEGIN
		SET @ValidUser = ''
		IF CHARINDEX(',',@ValidList) > 0
			SET  @ValidUser = SUBSTRING(@ValidList,0,CHARINDEX(',',@ValidList))
	
		ELSE
		BEGIN
			SET @ValidUser = @ValidList
			SET @ValidList = ''
		END
	
		INSERT INTO  #ValidTemp (ValidUser) VALUES (@ValidUser)
		SET @ValidList = REPLACE(@ValidList,@ValidUser + ',' , '')
	END

	DECLARE TABLE_CURSOR CURSOR LOCAL FOR
	SELECT TABLE_NAME, TABLE_SCHEMA
	FROM INFORMATION_SCHEMA.Tables 
	WHERE 
		TABLE_TYPE = 'BASE TABLE' 
			AND TABLE_NAME != 'sysdiagrams'
			AND TABLE_NAME LIKE  ('%' + @AuditNameExtention)
			AND
			 (TABLE_SCHEMA IN (SELECT ValidSchema FROM #ValidSchema)
				OR (SELECT COUNT(*) FROM #ValidSchema) = 0)
			AND
			 (TABLE_SCHEMA NOT IN (SELECT InValidSchema FROM #InvalidSchema)
				OR (SELECT COUNT(*) FROM #InvalidSchema) = 0)

	OPEN TABLE_CURSOR
	FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME, @TABLE_SCHEMA

	IF (SELECT COUNT(*) FROM #InvalidTemp) > 0
		SELECT * FROM #InvalidTemp
	IF (SELECT COUNT(*) FROM #ValidTemp) > 0
		SELECT * FROM #ValidTemp
	IF (SELECT COUNT(*) FROM #InvalidSchema) > 0
		SELECT * FROM #ValidSchema
	IF (SELECT COUNT(*) FROM #ValidSchema) > 0
		SELECT * FROM #InvalidSchema
	IF (SELECT COUNT(*) FROM #InvalidTable) > 0
		SELECT * FROM #ValidSchema
	IF (SELECT COUNT(*) FROM #ValidTable) > 0
		SELECT * FROM #InvalidSchema

	WHILE @@FETCH_STATUS = 0
	BEGIN --> 2
		SET @BlankColumns = ''

		DECLARE COLUMN_CURSOR CURSOR LOCAL FOR
		SELECT COLUMN_NAME, COALESCE(COLUMN_DEFAULT,'NULL')
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE 1=1
			AND table_schema = @TABLE_SCHEMA
			AND table_name = @TABLE_NAME

		OPEN COLUMN_CURSOR
		FETCH NEXT FROM COLUMN_CURSOR INTO @ColumnName, @ColumnDefault
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @BlankColumns = @BlankColumns + ', ' + @ColumnDefault + ' AS ' + @ColumnName
			FETCH NEXT FROM COLUMN_CURSOR INTO @ColumnName, @ColumnDefault
		END
		CLOSE COLUMN_CURSOR
		DEALLOCATE COLUMN_CURSOR
		SET @BlankColumns = RIGHT(@BlankColumns,LEN(@BlankColumns)-1)

		SELECT @SQL = ' SELECT ''' + @TABLE_SCHEMA + '.' + @TABLE_NAME + ''' AS TableName, ' + @BlankColumns + @CRLF

		SET @SQL = @SQL +  ' UNION ALL ' + @CRLF

		SET @SQL = @SQL + ' SELECT ''' + @TABLE_SCHEMA + '.' + @TABLE_NAME + ''' AS TableName, * ' + @CRLF
			+ ' FROM ' + @TABLE_SCHEMA + '.' + @TABLE_NAME + @CRLF
			+ ' WHERE (UserName NOT LIKE ''' + @ValidUserPrefix + '%''' + @CRLF
			+ '			AND UserName NOT IN (SELECT * FROM #ValidTemp)) ' + @CRLF
			+ '		OR UserName IN (SELECT InvalidUser FROM #InvalidTemp) '
		IF @PrintQuery = 1
			PRINT @SQL
		EXEC (@SQL)

		IF @DeleteRows = 1
		BEGIN --> 3
			SET @SQL = ' DELETE ' + @CRLF
				+ ' FROM ' + @TABLE_SCHEMA + '.' + @TABLE_NAME + @CRLF
				+ ' WHERE (UserName NOT LIKE ''' + @ValidUserPrefix + '%''' + @CRLF
				+ '			AND UserName NOT IN (SELECT * FROM #ValidTemp)) ' + @CRLF
				+ '		OR UserName IN (SELECT InvalidUser FROM #InvalidTemp) '
		IF @PrintQuery = 1
			PRINT @SQL
		EXEC (@SQL)
		END --< 3
		FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME, @TABLE_SCHEMA
	END --< 2
	CLOSE TABLE_CURSOR
	DEALLOCATE TABLE_CURSOR
	DROP TABLE #InvalidTemp
	DROP TABLE #ValidTemp
END --< 1