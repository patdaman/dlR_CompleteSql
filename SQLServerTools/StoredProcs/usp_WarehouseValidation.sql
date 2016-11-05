-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-29
-- Description:	Run a differencial query 
--				between database instances.
--
--				Output is only Orig / New
--				concatenated into each row
--				where one or more columns
--				does not match
-- 
--				User Input:
--				Provide two instance names 
--				{machinename}, 

--				Column_Names is CSV input
--				of column names to compare.
--
--				Default Column_Names {null} 
--				will compare all columns.
--
--				StartDate / EndDate = OrderDate
--  
CREATE PROCEDURE [dbo].[usp_WarehouseValidation] 
	@OrigInstance	varchar(128)
	, @NewInstance	varchar(128)
	, @Column_Names	VARCHAR(MAX)
	, @StartDate	datetime
	, @EndDate		datetime
	, @Database		varchar(128) = null
	, @Schema		varchar(128) = null
	, @View			varchar(128) = null
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Column			VARCHAR(MAX)
	DECLARE @Columns		VARCHAR(MAX)
	DECLARE @ColumnCompare	VARCHAR(MAX)
	DECLARE @DateCompare	VARCHAR(MAX)
	DECLARE @SQL			VARCHAR(MAX)
	DECLARE @CRLF			VARCHAR(2)
	
	CREATE TABLE #Columns (ColumnName VARCHAR(MAX))

	SET @CRLF = CHAR(13) + CHAR(10)

	SET @StartDate		= COALESCE(@StartDate, '19000101')
	SET @EndDate		= COALESCE(@EndDate, GETDATE())
	SET @Column_Names	= COALESCE(@Column_Names, '')
	IF @Column_Names	= ''
		SET @Column_Names = '*'
	SET @Columns		= ''
	SET @ColumnCompare	= ''
	SET @DateCompare	= '		(I1.OrderDate > ' + '''' + CONVERT(VARCHAR(24),@StartDate,121) + ''''
		+ '		AND I1.OrderDate < ''' + CONVERT(VARCHAR(24),@EndDate,121) + ''')' + @CRLF
	SET @SQL			= CAST('' AS varchar(MAX))
	SET @OrigInstance	= COALESCE(@OrigInstance, CONVERT(sysname, SERVERPROPERTY('servername')))
	SET @NewInstance	= COALESCE(@NewInstance, CONVERT(sysname, SERVERPROPERTY('servername')))
	SET @Database		= COALESCE(@Database, 'SGNL_WAREHOUSE')
	SET @Schema			= COALESCE(@Schema, 'dbo')
	SET @View			= COALESCE(@View, 'vi_apiGetBillingStatusCase')

	SELECT @OrigInstance = CASE WHEN @OrigInstance = CONVERT(sysname, SERVERPROPERTY('servername'))
		THEN ''
		ELSE '[' + @OrigInstance + '].'
		END

	SELECT @NewInstance = CASE WHEN @NewInstance = CONVERT(sysname, SERVERPROPERTY('servername'))
		THEN ''
		ELSE '[' + @NewInstance + '].'
		END

	IF @Column_Names = '*'
	BEGIN
		SET @SQL = ' INSERT INTO #Columns (ColumnName) ' + @CRLF
		SET @SQL = @SQL + ' SELECT COLUMN_NAME ' + @CRLF
		 + ' FROM [' + @Database + '].INFORMATION_SCHEMA.COLUMNS ' + @CRLF
		 + ' WHERE TABLE_NAME = ''' + @View + '''' + @CRLF
		 + '	AND TABLE_SCHEMA = ''' + @Schema + '''' + @CRLF
		 + '	AND COLUMN_NAME NOT IN (''CaseId'', ''CaseNumber'') ' + @CRLF
		 + '	AND COLUMN_NAME NOT LIKE ''Last%'' ' + @CRLF
		 PRINT @SQL
		 EXEC (@SQL)
		DECLARE ColumnList CURSOR LOCAL FOR
		SELECT ColumnName
		FROM #Columns
	END
	ELSE BEGIN
		DECLARE ColumnList CURSOR LOCAL FOR
		SELECT Item
		FROM [dbo].udf_DelimitedSplit(@Column_Names,',')
	END

	OPEN ColumnList

	FETCH NEXT FROM ColumnList INTO @Column
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @Column = RTRIM(LTRIM(@Column))
		SET @Columns = @Columns + ', I1.[' + @Column + '] AS [Orig_' + @Column + '], I2.[' + @Column + '] AS [New_' + @Column + ']' + @CRLF
		SET @ColumnCompare = @ColumnCompare + ' OR I1.[' + @Column + '] <> I2.[' + @Column + ']' + @CRLF
		FETCH NEXT FROM ColumnList INTO @Column
	END
	CLOSE ColumnList
	DEALLOCATE ColumnList

	IF LEN(@Columns) > 2
		SET @Columns = RIGHT(@Columns, LEN(@Columns) - 2)
	IF LEN(@ColumnCompare) > 4
		SET @ColumnCompare = RIGHT(@ColumnCompare, LEN(@ColumnCompare) - 3)
	--SET @SQL = ' USE ' + @Database + '; ' + @CRLF
	SET @SQL = --@SQL +
		' SELECT I1.CaseNumber, ' + @Columns + @CRLF
		+ ' FROM ' + @OrigInstance + @Database + '.' + @Schema + '.' + @View + ' AS I1 ' + @CRLF
		+ ' FULL OUTER JOIN ' + @NewInstance + @Database + '.' + @Schema + '.' + @View + ' AS I2 ' + @CRLF
		+ '		ON I1.CaseNumber = I2.CaseNumber ' + @CRLF
		+ ' WHERE (' + @CRLF
		+ @DateCompare + @CRLF
		+ ' AND ( ' + @CRLF
		+ @ColumnCompare + @CRLF
		+ ' )) '

	PRINT @SQL
	EXEC (@SQL)

	DROP TABLE #Columns
END