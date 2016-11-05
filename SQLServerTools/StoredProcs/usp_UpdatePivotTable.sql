-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-16
-- Description:	Takes a fully formed table, a Column name whos values will be used for distinct column pivot, and a fully formed Destination Table Name
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdatePivotTable] 
	@ColumnWithNewColumnNames	VARCHAR(128) = ''
	, @ColumnWithValues			VARCHAR(128) = ''
	, @DestinationTable			VARCHAR(128) = ''
	, @SourceTable				VARCHAR(128) = ''
	, @Key						VARCHAR(128) = ''
	, @NewKey					VARCHAR(128) = ''
	, @Rebuild					bit			 = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @cols		VARCHAR(MAX)
	DECLARE @query		VARCHAR(MAX)
	DECLARE @maxCols	VARCHAR(MAX)
	DECLARE @Column		VARCHAR(128)
	DECLARE @CRLF		VARCHAR(2)
	DECLARE @index		int
	DECLARE @Cases		CaseListType

	SET @CRLF = CHAR(13) + CHAR(10)
	SET @maxCols = ''

	CREATE TABLE #TEMP (ColumnName NVARCHAR(MAX));

	SELECT @query = ' INSERT INTO #TEMP ' + @CRLF
					+ ' select STUFF((SELECT distinct '','' +
							QUOTENAME(' + @ColumnWithNewColumnNames + ') ' + @CRLF
					+ '	  FROM ' + @SourceTable + @CRLF
					+ '	  FOR XML PATH(''''), TYPE ' + @CRLF
					+ '		 ).value(''.'', ''NVARCHAR(MAX)'') ' + @CRLF
					+ '		, 1, 1, '''') ' + @CRLF
					;
	EXECUTE(@query);
	
	SELECT @cols = ColumnName FROM #TEMP;

	CREATE TABLE #TEMP2 (ColumnName NVARCHAR(MAX));
	SELECT @query = ' INSERT INTO #TEMP2 ' + @CRLF
					+ ' SELECT DISTINCT QUOTENAME(' + @ColumnWithNewColumnNames + ') ' + @CRLF
					+ ' FROM ' + @SourceTable + @CRLF
					+ ' WHERE COALESCE(' + @ColumnWithNewColumnNames + ','''') <> '''' ' + @CRLF
					;
	EXECUTE(@query)

	DECLARE ColumnNameCursor CURSOR LOCAL FOR
	SELECT ColumnName FROM #TEMP2

	OPEN ColumnNameCursor
	FETCH NEXT FROM ColumnNameCursor INTO @Column
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @Column = @Key
			SET @maxCols = @maxCols + 'MAX(p.' + @Column + ') AS ' + @NewKey + ', '
		ELSE
			SET @maxCols = @maxCols + 'MAX(p.' + @Column + ') AS ' + @Column + ', '
		FETCH NEXT FROM ColumnNameCursor INTO @Column
	END

	SET @maxCols = LEFT(@maxCols, LEN(@maxCols) - 1)

	IF (NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = RIGHT(@DestinationTable, CHARINDEX('.',REVERSE(@DestinationTable)) -1))
		OR @Rebuild = 1)
	BEGIN
		IF EXISTS(SELECT 1 FROM sys.tables WHERE name = RIGHT(@DestinationTable, CHARINDEX('.',REVERSE(@DestinationTable)) -1))
		BEGIN
			SELECT @query = ' DROP TABLE ' + @DestinationTable 
			EXECUTE(@query)
		END

		SELECT @query = 'SELECT ' + @NewKey + ', ' + @cols + @CRLF
					+ ' INTO ' + @DestinationTable + @CRLF
					+ ' FROM ( SELECT ' + @Key + ' AS ' + @NewKey + ', ' + @maxCols + @CRLF
					+ '		FROM ' + @SourceTable + @CRLF
					+ ' PIVOT ' + @CRLF
					+ ' ( ' + @CRLF
					+ '   MAX(' + @ColumnWithValues + ') ' + @CRLF
					+ ' FOR ' + @ColumnWithNewColumnNames + ' in ( ' + @cols + '  ) ' + @CRLF
					+ ' ) AS p' + @CRLF
					+ ' GROUP BY ' + @Key + @CRLF
					+ ') X' + @CRLF
					;
	END
	ELSE BEGIN

		SELECT @query = ' INSERT INTO ' + @DestinationTable + @CRLF
						+ ' SELECT ' + @Key + ' AS ' + @NewKey + ', ' + @maxCols + @CRLF
						+ '		FROM ' + @SourceTable + ' S '+ @CRLF
						+ ' PIVOT ' + @CRLF
						+ ' ( ' + @CRLF
						+ '   MAX(' + @ColumnWithValues + ') ' + @CRLF
						+ ' FOR ' + @ColumnWithNewColumnNames + ' in ( ' + @cols + '  ) ' + @CRLF
						+ ' ) AS p' + @CRLF
						+ ' GROUP BY ' + @Key + @CRLF
						;
		CLOSE ColumnNameCursor
		DEALLOCATE ColumnNameCursor
	END

PRINT @query
	EXECUTE(@query);
	DROP TABLE #TEMP
END