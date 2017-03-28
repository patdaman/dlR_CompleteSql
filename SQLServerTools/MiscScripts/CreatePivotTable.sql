
BEGIN
DECLARE	@ColumnWithNewColumnNames	sysname = 'ComponentCode'				-- Pivot Column
DECLARE	@ColumnWithValues			sysname = 'DataValue'					-- Value Column
DECLARE	@DestinationTable			sysname = 'SGNL_LIS.dbo.CaseResults'	-- New Table (Temp Table fine as well)
DECLARE	@SourceTable				sysname = 'XifinLIS.dbo.XIFIN_Result'	-- Source Table
DECLARE @enumTable					sysname = 'SGNL_LIS.dbo.enum_ResultsDataTypes' -- table with data types and parsing function names
DECLARE	@Key						sysname = 'CaseNo'						-- Primary Key grouping for new table
DECLARE	@NewKey						sysname = 'CaseNumber'					-- New Primary Key Column Name
DECLARE	@minInstances				int = 0									-- having count() > @minInstances for pivot value to be included
DECLARE	@Aggregate					sysname = 'MAX'							-- group by aggregate function
DECLARE @CaseNumber					VARCHAR(MAX) = NULL						-- Optional.  Null = All Cases
DECLARE @DropRecreate				bit = 0									-- Setting this value to '1' will drop the destination table and recreate it
																			-- Setting to '0' will only print the query



/*	************************************************************************	*/
DECLARE @query						VARCHAR(MAX)
DECLARE @ColumnNames				VARCHAR(MAX)
DECLARE @ValueConversion			VARCHAR(MAX)
DECLARE @CRLF						VARCHAR(20) = CHAR(13) + CHAR(10)
DECLARE @FullDestinationTable		sysname

SET NOCOUNT ON;

IF LEFT(@DestinationTable, 1) = '#'
	SET @FullDestinationTable = 'tempdb..' + @DestinationTable 
ELSE
	SET @FullDestinationTable = @DestinationTable

IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL
	DROP TABLE #TEMP;
CREATE TABLE #TEMP (FunctionName NVARCHAR(MAX), ColumnName NVARCHAR(MAX));

IF OBJECT_ID('tempdb..#Cases') IS NOT NULL
	DROP TABLE #Cases;
CREATE TABLE #Cases (CaseNumber VARCHAR(50) NOT NULL)

IF @CaseNumber IS NULL
	INSERT INTO #Cases
	SELECT DISTINCT CaseNo
	FROM XifinLIS.dbo.XIFIN_Result
ELSE
	INSERT INTO #Cases
	SELECT @CaseNumber

SELECT @query = ' INSERT INTO #TEMP (FunctionName, ColumnName) ' + @CRLF
				+ ' SELECT REPLACE(COALESCE(MAX(enum.[Description]),''''),''()'',''(['' + ' + @ColumnWithNewColumnNames + ' + '']) AS ''), ''['' + [' + @ColumnWithNewColumnNames + '] + '']''' + @CRLF
				+ '	  FROM ' + @SourceTable + ' result ' + @CRLF
				+ '		LEFT OUTER JOIN ' + @enumTable + ' enum ON ''['' + result.' + @ColumnWithNewColumnNames + ' + '']'' = enum.id ' + @CRLF
				+ '		WHERE ' + @ColumnWithNewColumnNames + ' IS NOT NULL ' + @CRLF
				+ '		GROUP BY ' + @ColumnWithNewColumnNames + ', enum.[Description] ' + @CRLF
				+ '		HAVING COUNT(*) > ' + CONVERT(VARCHAR(10), @minInstances) + @CRLF
PRINT @query
EXEC(@query);
PRINT @CRLF + @CRLF

--Get distinct values of the PIVOT Column 
SELECT @ColumnNames = SignalFunctions.dbo.GROUP_CONCAT_D(ColumnName,',')
	, @ValueConversion = SignalFunctions.dbo.GROUP_CONCAT_D(FunctionName + ColumnName,',')
FROM #TEMP

	
IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL
	DROP TABLE #TEMP;
	
SELECT @query = ' IF OBJECT_ID(''' + @FullDestinationTable + ''') IS NOT NULL ' + @CRLF
	+ '		DROP TABLE ' + @FullDestinationTable
PRINT @query
IF @DropRecreate = 1
	EXEC (@query);
PRINT  @CRLF + @CRLF

SELECT @query = 'SELECT [' + @NewKey + '], ' + @ValueConversion + @CRLF
				+ ' INTO ' + @DestinationTable + @CRLF
				+ ' FROM ( SELECT [' + @Key + '] AS [' + @NewKey + '], [' + @ColumnWithNewColumnNames + ']' + @CRLF
				+ '		, [' + @ColumnWithValues + ']' + @CRLF
				+ '		FROM ' + @SourceTable + ' Source ' + @CRLF
				+ '			INNER JOIN #Cases ON Source.' + @Key + ' = #Cases.CaseNumber ' + @CRLF
				+ ') AS t ' + @CRLF
				+ ' PIVOT ' + @CRLF
				+ ' ( ' + @CRLF
				+ '   ' + @Aggregate + '(' + @ColumnWithValues + ') '  + @CRLF
				+ ' FOR [' + @ColumnWithNewColumnNames + '] in ( ' + @ColumnNames + '  ) ' + @CRLF
				+ ' ) AS p' + @CRLF
				;
PRINT @query
IF @DropRecreate = 1
BEGIN
	EXEC (@query);
	SET @query = ' SELECT * ' + @CRLF
		+ ' FROM ' + @DestinationTable
	PRINT @query
	EXEC (@query);
END

END