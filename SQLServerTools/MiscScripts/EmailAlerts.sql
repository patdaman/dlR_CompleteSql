use [master]
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell',1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1
GO
RECONFIGURE
GO

USE [XifinLIS]
;

CREATE TABLE #ImportAlertSettings
(	CaseNumber VARCHAR(256)
	, LastUTCImportTime DateTime2(7)
	, LastCreatedDate DateTimeOffset(0)
	, AccessionId int
)
;

INSERT INTO #ImportAlertSettings (CaseNumber, LastUTCImportTime, LastCreatedDate, AccessionId)
SELECT Top 1 CaseNumber
	, C.ReceiveUTCDate
	, C.CreatedDate
	, C.AccessionId
FROM XifinLIS.dbo.XIFIN_LabMessage_Case C
ORDER BY C.ReceiveUTCDate DESC
;

DECLARE @sql VARCHAR(MAX)
DECLARE @recipients VARCHAR(MAX)
DECLARE @message VARCHAR(MAX)
DECLARE @copy_recipients VARCHAR(MAX)
DECLARE @subject VARCHAR(MAX)
DECLARE @CaseNumber VARCHAR(MAX)
DECLARE @LastUTCImportTime DateTime2(7)
DECLARE	@LastCreatedDate DateTimeOffset(0)
DECLARE @AccessionId int
DECLARE @ProfileName VARCHAR(128)
DECLARE @CRLF VARCHAR(2)

SELECT Top 1 @CaseNumber = CaseNumber
		, @LastUTCImportTime = LastUTCImportTime
		, @LastCreatedDate = LastCreatedDate
		, @AccessionId = AccessionId
FROM #ImportAlertSettings
DROP TABLE #ImportAlertSettings;

SET @CRLF = Char(13) + Char(10)
SET @recipients = 'pdelosreyes@SignalGenetics.com'
SET @ProfileName = 'DbMail'
SET @copy_recipients = ''
SET @subject = 'Test'
SET @message = 'Last Message Received at ' + @CRLF
	+ COALESCE(CONVERT(VARCHAR(128), @LastUTCImportTime, 110),'') + @CRLF
	+ 'Last Message Created Date: '
	+ COALESCE(CONVERT(VARCHAR(128), @LastCreatedDate, 110),'') + @CRLF
	+ 'AccessionId: ' + COALESCE(CAST(@AccessionId AS VARCHAR(20)),'') + @CRLF
	+ 'CaseNumber(s): ' + COALESCE(@CaseNumber,'') + @CRLF

IF ((@LastUTCImportTime < DATEADD(dd,-1,GETDATE()) OR @LastCreatedDate < DATEADD(dd,-1,GETDATE()))
	AND DATENAME(dw,GETDATE()) <> 'Sunday' AND DATENAME(dw,GETDATE()) <> 'Monday'
	)
BEGIN
	EXEC [msdb].[dbo].[sp_send_dbmail]
	@profile_name='Tester',
		@recipients= @recipients,
		@body=@message,
		@copy_recipients=@copy_recipients,
		@subject=@subject ;
END
