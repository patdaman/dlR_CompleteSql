
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2016-02-02
-- Description:	Output table to CSV
--
-- =============================================
CREATE PROCEDURE [dbo].[usp_Report_WriteCsvToDisk] 
	@SaveLocation				VARCHAR(MAX)
	, @Filename					VARCHAR(MAX)
	, @Query					VARCHAR(MAX)
	, @TempTableName			sysname
	, @Servername				sysname
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrorMessage		VARCHAR(MAX)
	DECLARE @CRLF	VARCHAR(2)
	DECLARE @SQL	VARCHAR(MAX)

	/* ************************************************************************************** */
	/* *************************** NULL Input Failover Section ****************************** */
	/* ************************************************************************************** */

	SET @Servername = COALESCE(@Servername, CONVERT(VARCHAR(128), SERVERPROPERTY('MachineName')))
	SET @SaveLocation = COALESCE(@SaveLocation, '')
	SET @Query = COALESCE(@Query, '')
	SET @TempTableName = COALESCE(@TempTableName, '')

	/* ************************************************************************************** */
	/* ********************************* No Edits Below Here!! ****************************** */
	/* ************************************************************************************** */

	IF (@SaveLocation = '')
	BEGIN 
		SET @ErrorMessage = 'No save location provided.'
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END 

	IF (@Query = '' AND @TempTableName = '')
	BEGIN
		SET @ErrorMessage = 'Csv write utility will not accept a blank query and no temp table.'
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END 

	IF (@TempTableName = '')
	BEGIN
		SET @TempTableName = '#WriteCsvToDisk'
		SET @SQL = ' SELECT * ' + @CRLF
			+ ' INTO #WriteCsvToDisk ' + @CRLF
			+ ' FROM ( ' + @CRLF 
			+ @QUERY + @CRLF
			+ ' ) WriteCsvToDisk ' + @CRLF
		
		BEGIN TRY
			EXEC (@SQL);
			IF OBJECT_ID('tempdb..#WriteCsvToDisk') IS NULL
			BEGIN
				SET @ErrorMessage = '#WriteCsvToDisk does not exist.'
				RAISERROR(@ErrorMessage, 16, 1)
				RETURN
			END
		END TRY
		BEGIN CATCH
			SET @ErrorMessage = 'Could not create a temp table from @Query .'
				+ 'Error Number: ' + ERROR_NUMBER() + @CRLF 
				+ ERROR_MESSAGE()
			RAISERROR(@ErrorMessage, 16, 1)
			RETURN
		END CATCH
	END

	BEGIN TRY

		/* ----------------------------------- */
		/* -------- Enable xp_cmdshell ------- */
		/* ----------------------------------- */
		EXEC sp_configure 'show advanced options', 1;
		RECONFIGURE;
		EXEC sp_configure 'xp_cmdshell',1
		RECONFIGURE

		/* ----------------------------------- */
		/* ----- Create the mapped drive ----- */
		/* ----------------------------------- */
		DECLARE @CMD			VARCHAR(4000)
		SET @CMD = 'net use V: ' + @SaveLocation + ' 93bd62e1adFB9007a4731bf97c201e3c! /USER:SGNL\DatabaseBackup /persistent:no'  
		EXEC master..XP_CMDSHELL @CMD
		/* ----------------------------------- */

		SET @CRLF	= CHAR(13) + CHAR(10)
		SET @SQL = ' '
		IF RIGHT(@SaveLocation,1) = '\'
			SET @SaveLocation = LEFT(@SaveLocation, LEN(@SaveLocation) - 1)
		SET @CMD = 'bcp ' + @TempTableName + ' out V:\' + @Filename + ' -w -T -S ' + @Servername 
		--PRINT @SQL
		EXEC master..xp_cmdshell @CMD

		/* ----------------------------------- */
		/* ----- Delete the mapped drive ----- */
		/* ----------------------------------- */
		EXEC XP_CMDSHELL 'net use V: /delete'

		/* ----------------------------------- */
		/* ----- Disable xp_cmdshell ----- */
		/* ----------------------------------- */
		EXEC sp_configure 'show advanced options', 1;
		RECONFIGURE;
		EXEC sp_configure 'xp_cmdshell',0
		RECONFIGURE
	END TRY
	BEGIN CATCH
		SET @ErrorMessage = 'File Not Saved.' + @CRLF
			+ 'Error Number: ' + ERROR_NUMBER() + @CRLF 
			+ ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END CATCH
END