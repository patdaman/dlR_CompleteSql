-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2016-02-02
-- Description:	Output table to CSV
-- =============================================
CREATE PROCEDURE [dbo].[usp_Report_EmailCsv] 

	@Recipients					VARCHAR(MAX)
	, @ProfileName				sysname
	, @Database					sysname
	, @Query					VARCHAR(8000)
	, @Filename					VARCHAR(MAX)
	, @Subject					VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	/* ************************************************************************************** */
	/* *************************** NULL Input Failover Section ****************************** */
	/* ************************************************************************************** */

	SET @Recipients = COALESCE(@Recipients, 'pdelosreyes@signalgenetics.com')
	SET @Database = COALESCE(@Database, 'SGNL_WAREHOUSE')
	SET @ProfileName = COALESCE(@ProfileName, 'DbMail') -- 'IS Alerts' --< On APP Server

	/* ************************************************************************************** */
	/* ********************************* No Edits Below Here!! ****************************** */
	/* ************************************************************************************** */

	DECLARE @CRLF			VARCHAR(2)
	DECLARE @ErrorMessage	sysname

	IF (@ProfileName NOT IN (
			SELECT name
			FROM msdb.dbo.sysmail_profile)
		)
	BEGIN 
		SET @ErrorMessage = 'DB Mail Profile Name does not exist.' + @CRLF
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END 

	IF (@Query IS NULL)
	BEGIN
		SET @ErrorMessage = 'DB Mail will not accept a blank query.' + @CRLF
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END 

	/* -- Don't get it, AAAAAAHHHHHH!!!!!! -- */
	/* -- PdlR 20160202 -- */
	--SET @Query = CONVERT(VARCHAR(8000), ' SET NOCOUNT ON; ' + @CRLF + @Query)

	BEGIN TRY
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @ProfileName,
			@execute_query_database = @Database,
			@recipients = @Recipients,
			@query = @Query,
			@body = @Query,
			@subject = @Subject,
			@query_result_header = 1,
			@exclude_query_output = 1,
			@query_result_separator = '	',
			@query_attachment_filename = @Filename,
			@query_result_no_padding = 0,
			@query_no_truncate = 1,
			@query_result_width = 32767,
			@attach_query_result_as_file = 1 ;
	END TRY
	BEGIN CATCH
		SET @ErrorMessage = 'Mail Not Sent.' + @CRLF
			+ 'Error Number: ' + ERROR_NUMBER() + @CRLF 
			+ ERROR_MESSAGE()
		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END CATCH
END