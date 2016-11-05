
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-07
-- Description:	View errors accross all DBs
-- =============================================
CREATE PROCEDURE [dbo].[usp_ViewErrorTables] 
	@StartDate	datetime = NULL
	, @EndDate	datetime = NULL
	, @Rows		int = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL	VARCHAR(MAX)
	DECLARE @CRLF	VARCHAR(2)

	SET @CRLF		= CHAR(13) + CHAR(10)
	SET @StartDate	= COALESCE(@StartDate, '19000101')
	SET @EndDate	= COALESCE(@EndDate, GETUTCDATE())

	IF @Rows <> 0
		SET @SQL = ' SELECT TOP ' + CAST(@Rows AS varchar(10)) + ' * ' + @CRLF
	ELSE
		SET @SQL = ' SELECT * ' + @CRLF
	
	SET @SQL = @SQL + ' FROM ( ' + @CRLF

	IF EXISTS(SELECT 1 FROM SGNL_LIS.sys.tables WHERE NAME = 'ErrorTracer')
		SET @SQL = @SQL + ' SELECT ''SGNL_LIS'' AS DbName '
			+ ' , * ' + @CRLF
			+ ' FROM [SGNL_LIS].[dbo].[ErrorTracer] ' + @CRLF
			+ @CRLF
			+ ' UNION ALL ' + @CRLF

	IF EXISTS(SELECT 1 FROM SGNL_INTERNAL.sys.tables WHERE NAME = 'ErrorTracer')
		SET @SQL = @SQL + ' SELECT ''SGNL_INTERNAL'' AS DbName ' + @CRLF
			+ ' , * ' + @CRLF
			+ ' FROM [SGNL_INTERNAL].[dbo].[ErrorTracer] ' + @CRLF
			+ @CRLF
			+ ' UNION ALL ' + @CRLF

	IF EXISTS(SELECT 1 FROM SGNL_FINANCE.sys.tables WHERE NAME = 'ErrorTracer')
		SET @SQL = @SQL + ' SELECT ''SGNL_FINANCE'' AS DbName ' + @CRLF
			+ ' , * ' + @CRLF
			+ ' FROM [SGNL_FINANCE].[dbo].[ErrorTracer] ' + @CRLF
			+ @CRLF
			+ ' UNION ALL ' + @CRLF

	IF EXISTS(SELECT 1 FROM SGNL_WAREHOUSE.sys.tables WHERE NAME = 'ErrorTracer')
		SET @SQL = @SQL + ' SELECT ''SGNL_WAREHOUSE'' AS DbName ' + @CRLF
			+ ' , * ' + @CRLF
			+ ' FROM [SGNL_WAREHOUSE].[dbo].[ErrorTracer] ' + @CRLF
			+ @CRLF
			+ ' UNION ALL ' + @CRLF

	IF EXISTS(SELECT 1 FROM XifinLIS.sys.tables WHERE NAME = 'ErrorTracer')
		SET @SQL = @SQL + ' SELECT ''XifinLIS'' AS DbName ' + @CRLF
			+ ' , * ' + @CRLF
			+ ' FROM [XifinLIS].[dbo].[ErrorTracer] ' + @CRLF

	IF RIGHT(@SQL, 11) = ' UNION ALL '
		SET @SQL = LEFT(@SQL,LEN(@SQL)-11)

	SET @SQL = @SQL + ') X ' + @CRLF

	SET @SQL = @SQL + ' WHERE dErrorDate >= ''' + CONVERT(VARCHAR(20), @StartDate, 110) + ''''
		+ ' AND dErrorDate <= ''' + CONVERT(VARCHAR(20), @EndDate, 110) + ''''

	SET @SQL = @SQL + ' ORDER BY dErrorDate DESC ' + @CRLF

	PRINT @SQL
	EXEC (@SQL)

END