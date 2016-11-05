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
DECLARE @CRLF VARCHAR(2)

SELECT Top 1 @CaseNumber = CaseNumber
		, @LastUTCImportTime = LastUTCImportTime
		, @LastCreatedDate = LastCreatedDate
		, @AccessionId = AccessionId
FROM #ImportAlertSettings
DROP TABLE #ImportAlertSettings;

SET @CRLF = Char(13) + Char(10)
SET @recipients = 'pdelosreyes@SignalGenetics.com'
SET @copy_recipients = ''
SET @subject = 'Test'
SET @message = 'Last Message Received at ' + @CRLF
	+ CONVERT(VARCHAR(128), @LastUTCImportTime, 110) + @CRLF
	+ 'Last Message Created Date: '
	+ CONVERT(VARCHAR(128), @LastCreatedDate, 110) + @CRLF
	+ 'AccessionId: ' + CAST(@AccessionId AS VARCHAR(20)) + @CRLF
	+ 'CaseNumber(s): ' + @CaseNumber + @CRLF

EXEC master.dbo.xp_sendmail 
    @recipients= @recipients,
     @message=@message,
     @copy_recipients=@copy_recipients,
     @subject=@subject ;

DROP TABLE #ImportAlertSettings;