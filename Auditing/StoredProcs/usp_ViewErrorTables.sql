
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
		SET @SQL = @SQL + ' SELECT * ' + @CRLF
			+ ' FROM [dbo].[ErrorTracer] ' + @CRLF

	PRINT @SQL
	EXEC (@SQL)

END