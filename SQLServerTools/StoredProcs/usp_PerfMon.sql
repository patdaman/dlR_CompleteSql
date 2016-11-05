
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-08
-- Description:	Run PerfMon command line interface
-- =============================================
CREATE PROCEDURE [dbo].[usp_PerfMon]
	@ServerName				VARCHAR(128)
	, @ODBCName				VARCHAR(128)
	, @DefinitionFilePath	VARCHAR(256)
	, @DisplayName			VARCHAR(128)
	, @Minutes				INT			 = 1
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Command	VARCHAR(8000)
	DECLARE @TestName	VARCHAR(128)
	DECLARE @Time		INT

	SET @Time = @Minutes * 10

	SET @Command = 'TYPEPERF -f SQL -s "' + @ServerName + '" -cf "' + @DefinitionFilePath + '" -si 10 -o SQL:' + @ODBCName + '!' + @DisplayName + ' -sc ' + CAST(@Time AS VARCHAR(10))
	EXEC master..XP_CMDSHELL @Command

END