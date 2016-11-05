
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-16
-- Description:	Takes a fully formed table,
--				a Column name whos values will be used for distinct column pivot, 
--				and a fully formed Destination Table Name
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreatePivotTable] 
	@ColumnWithNewColumnNames	sysname = ''
	, @ColumnWithValues			sysname = ''
	, @ValueType				sysname = 'VARCHAR(MAX)'
	, @SourceTable				sysname = ''
	, @Key						sysname = ''
	, @DestinationTable			sysname = ''
	, @NewKey					sysname = ''
	, @minInstances				int	= 0
	, @Aggregate				sysname = 'MIN'

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @query				VARCHAR(MAX)
	DECLARE @ColumnNames		VARCHAR(MAX)
	DECLARE @ValueConversion	VARCHAR(500)
	DECLARE @CRLF				VARCHAR(20) = CHAR(13) + CHAR(10)

	SET @ValueConversion = @ColumnWithValues

	IF @ValueType IN ('INT','DECIMAL','FLOAT')
		SET @ValueConversion = 'dbo.RegExReplace(COALESCE(' + @ColumnWithValues + N',CAST(0 AS FLOAT)), N''(?<=^| )\d+(\.\d+)?(?=$| )|(?<=^| )\.\d+(?=$| )'','''')'

	IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL
		DROP TABLE #TEMP;
	CREATE TABLE #TEMP (ColumnName NVARCHAR(MAX));

	SELECT @query = ' INSERT INTO #TEMP (ColumnName) ' + @CRLF
					+ ' SELECT ' + @ColumnWithNewColumnNames + @CRLF
					+ '	  FROM ' + @SourceTable  + @CRLF
					+ '		GROUP BY ' + @ColumnWithNewColumnNames + @CRLF
					+ ' HAVING COUNT(*) > ' + CONVERT(VARCHAR(10), @minInstances) + @CRLF
--PRINT @query
	EXEC(@query);

	--Get distinct values of the PIVOT Column 
	SELECT @ColumnNames = ISNULL(@ColumnNames + ',','') 
		   + QUOTENAME(ColumnName)
	FROM (SELECT DISTINCT ColumnName FROM #TEMP) AS ColumnName
	
	SELECT @query = ' IF OBJECT_ID(''' + @DestinationTable + ''',''U'') IS NOT NULL ' + @CRLF
		+ '		DROP TABLE ' + @DestinationTable
--PRINT @query
	EXEC (@query);

	IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL
		DROP TABLE #TEMP;

	SELECT @query = 'SELECT ' + @NewKey + ', ' + @ColumnNames + @CRLF
					+ ' INTO ' + @DestinationTable + @CRLF
					+ ' FROM ( SELECT (' + @Key + ') AS ' + @NewKey + ', ' + @ColumnWithNewColumnNames + @CRLF
					+ '		, CONVERT(' + @ValueType + ', ' + @ValueConversion + ') AS ' + @ColumnWithValues  + @CRLF
					+ '		FROM ' + @SourceTable + ') AS t ' + @CRLF
					+ ' PIVOT ' + @CRLF
					+ ' ( ' + @CRLF
					+ '   ' + @Aggregate + '(' + @ColumnWithValues + ') '  + @CRLF
					+ ' FOR ' + @ColumnWithNewColumnNames + ' in ( ' + @ColumnNames + '  ) ' + @CRLF
					+ ' ) AS p' + @CRLF
					;
PRINT @query
	EXEC (@query);
END