CREATE PROCEDURE [dbo].[usp_InsertErrorDetails]
AS

BEGIN --> 1
  SET NOCOUNT ON 

  IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ErrorTracer')
  BEGIN --> 2
	CREATE TABLE [dbo].[ErrorTracer](
		[ErrorID] [int] IDENTITY(1,1) NOT NULL,
		[ErrorNumber] [int] NULL,
		[ErrorState] [int] NULL,
		[ErrorSeverity] [int] NULL,
		[ErrorLine] [int] NULL,
		[ErrorProc] [varchar](max) NULL,
		[ErrorMsg] [varchar](max) NULL,
		[UserName] [varchar](max) NULL,
		[HostName] [varchar](max) NULL,
		[ErrorDate] [datetime] NULL DEFAULT (getdate()),
	PRIMARY KEY CLUSTERED 
	(
		[ErrorID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
  END --< 2

  SET XACT_ABORT ON
  
  DECLARE @ErrorNumber VARCHAR(MAX)  
  DECLARE @ErrorState VARCHAR(MAX)  
  DECLARE @ErrorSeverity VARCHAR(MAX)  
  DECLARE @ErrorLine VARCHAR(MAX)  
  DECLARE @ErrorProc VARCHAR(MAX)  
  DECLARE @ErrorMesg VARCHAR(MAX)  
  DECLARE @UserName VARCHAR(MAX)  
  DECLARE @HostName VARCHAR(MAX) 

  SELECT  @ErrorNumber	= COALESCE(ERROR_NUMBER(), 'N/A')
       ,@ErrorState		= COALESCE(ERROR_STATE(), 'N/A')
       ,@ErrorSeverity	= COALESCE(ERROR_SEVERITY(), 'N/A')
       ,@ErrorLine		= COALESCE(ERROR_LINE(), 'N/A')
       ,@ErrorProc		= COALESCE(ERROR_PROCEDURE(), 'N/A')
       ,@ErrorMesg		= COALESCE(ERROR_MESSAGE(), 'N/A')
       ,@UserName		= COALESCE(SUSER_SNAME(), 'N/A')
       ,@HostName		= COALESCE(Host_NAME(), 'N/A')
  
	INSERT INTO ErrorTracer(ErrorNumber, ErrorState, ErrorSeverity, ErrorLine, ErrorProc, ErrorMsg, UserName, HostName, ErrorDate)  
	VALUES(@ErrorNumber
		,@ErrorState
		,@ErrorSeverity
		,@ErrorLine
		,@ErrorProc
		,@ErrorMesg
		,@UserName
		,@HostName
		,GETDATE()
		)

	-- Only send out email on production server
	IF(SERVERPROPERTY('MachineName') = '!!USER SET PRODUCTION MACHINE!!')
	BEGIN
		--
		--select the contents into an html table to return
		--
		DECLARE @tblBodyNull		VARCHAR(MAX)
		DECLARE @tblBody			VARCHAR(MAX)
		DECLARE @sBodyIntro			VARCHAR(MAX)
		DECLARE @sSubj NVARCHAR(MAX)

		SET @tblBody = CAST( (
			SELECT td = @HostName + '</td>
					<td>' + DB_NAME() + '</td>
					<td>' + @ErrorProc + '</td>
					<td>' + @ErrorLine + '</td>
					<td>' + @ErrorMesg + '</td>
					<td>' + @UserName + '</td>
					<td>' + CONVERT(VARCHAR(20), GETDATE(), 113) + '</td>'
			FOR XML PATH( 'tr' ), TYPE) AS VARCHAR(MAX))

		--
		-- prepare the body of the email with the table contents
		--
		SET @sBodyIntro = @ErrorProc + ' Generated Error while processing on ' + @@SERVERNAME
		SET @sSubj = 'ERROR on ' + @ErrorProc + ' on host: ' +  @@SERVERNAME 
		SET @tblBody = 
				@sBodyIntro + '<br /><br /><table cellpadding="2" cellspacing="2" border="1">'
				+ '<tr>
				<th>Host</th>
				<th>Database</th> 
				<th>Procedure</th>
				<th>Error Line</th>
				<th>Error Message</th> 
				<th>User</th> 
				<th>Date</th> 
				</tr>'
				+ REPLACE(REPLACE( @tblBody, '&lt;', '<' ), '&gt;', '>' )
				+ '</table>'

		--	
		-- Send email if Machine Name matches production
		--	

		EXEC [msdb].[dbo].[sp_send_dbmail] 
			@profile_name = '!!DBMAIL PROFILE NAME!!'
			,@recipients = '!!EMAIL RECIPIENT!!'				
			,@subject= @sSubj
			,@body_format = 'HTML'
			,@body= @tblBody
	END
END

IF OBJECT_ID('Proc_InsertErrorDetails') IS NOT NULL
BEGIN
    PRINT 'Procedure Proc_InsertErrorDetails Created'
END

