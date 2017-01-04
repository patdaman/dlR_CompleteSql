SET NOCOUNT ON;

DECLARE @MachineName	VARCHAR(128)
DECLARE @BackupPath 	VARCHAR(500)
DECLARE @DbName 		VARCHAR(128)

SET @BackupPath = CAST('$(BackupPath)' AS VARCHAR(128))
SET @DbName = CAST('$(DbName)' AS VARCHAR(128))
SET @MachineName = CAST(COALESCE('$(MachineName)',SERVERPROPERTY('MachineName')) AS VARCHAR(128))

/* --------------------------------------------- */
/* ------------ Backup Databases --------------- */

DECLARE @mdf	VARCHAR(256)
DECLARE @ldf	VARCHAR(256)
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @previousFileDate VARCHAR(20) -- used for file name
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @SQL VARCHAR(MAX)
DECLARE @result INT
DECLARE @CRLF VARCHAR(10)
SET @CRLF = CHAR(13) + CHAR(10)

-- specify filename format
SELECT @fileDate = LEFT(CONVERT(VARCHAR(20),GETDATE(),20), 10)
SELECT @previousFileDate = LEFT(CONVERT(VARCHAR(20),DATEADD(dd,-1,GETDATE()),20), 10)
IF RIGHT(@BackupPath,1)<>'\'
	SET @BackupPath = @BackupPath + '\'

IF OBJECT_ID('tempdb..#BACKUP_SETTINGS') IS NOT NULL
	DROP TABLE #BACKUP_SETTINGS;

CREATE TABLE #BACKUP_SETTINGS
(	BACKUP_PATH VARCHAR(256)
	, DbName sysname
	, MDF	VARCHAR(128)
	, LDF	VARCHAR(128)
);
INSERT INTO #BACKUP_SETTINGS (BACKUP_PATH, DbName)
VALUES (@BackupPath, @DbName)

SET @SQL = 'USE [' + @DbName + '];' + @CRLF
SET @SQL = @SQL 
		+ ' UPDATE #BACKUP_SETTINGS ' + @CRLF
		+ ' SET MDF = ( ' + @CRLF
		+ '		SELECT TOP 1 physical_name ' + @CRLF
		+ '		FROM sys.database_files ' + @CRLF
		+ '		WHERE RIGHT(RTRIM(physical_name),3) = ''mdf'' ' + @CRLF
		+ '		); ' + @CRLF
SET @SQL = @SQL
		+ ' UPDATE #BACKUP_SETTINGS ' + @CRLF
		+ ' SET LDF = ( ' + @CRLF
		+ '		SELECT TOP 1 physical_name ' + @CRLF
		+ ' 	FROM sys.database_files ' + @CRLF
		+ ' 	WHERE RIGHT(RTRIM(physical_name),3) = ''ldf'' ' + @CRLF
		+ ' 	);' + @CRLF
		EXEC (@SQL)
SELECT TOP 1 @mdf = MDF, @ldf = LDF
FROM #BACKUP_SETTINGS
WHERE DbName = @DbName

SET @fileName = @BackupPath + @fileDate + '_' + @MachineName + '_' + @DbName + '.bak'

EXEC master.dbo.xp_fileexist @fileName, @result OUTPUT
IF (@result <> 1)
BEGIN
	SET @fileName = @BackupPath + @previousFileDate + '_' + @MachineName + '_' + @DbName + '.bak'
END

EXEC master.dbo.xp_fileexist @fileName, @result OUTPUT
--IF (@result = 1)
IF (1=1)
BEGIN
BEGIN TRY
	SET @SQL = ' USE master;' + @CRLF

	SET @SQL = @SQL + ' ALTER DATABASE ' + @DbName + @CRLF
		+ ' SET SINGLE_USER WITH ' + @CRLF
		+ ' ROLLBACK IMMEDIATE; ' + @CRLF
PRINT @SQL
	EXEC (@SQL)

	SET @SQL = ' USE master;' + @CRLF
	----Restore Database
	SET @SQL = @SQL + ' RESTORE DATABASE ' + @DbName + @CRLF
		+ ' FROM DISK = ''' + @fileName + '''' + @CRLF
		+ ' WITH REPLACE ' + @CRLF
		+ '		, RECOVERY ' + @CRLF
		+ ' 	, MOVE ''' + @DbName + ''' TO ''' + @mdf + ''' ' + @CRLF
		+ ' 	, MOVE ''' + @DbName + '_log'' TO ''' + @ldf + ''' ' + @CRLF
PRINT @SQL
	EXEC (@SQL)
END TRY
BEGIN CATCH
	PRINT '!!!!!!!!!!!!!!!!!!!Didn''t work out!!!!!!!!!!!!!!!!!!!!!'
	PRINT 'Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + CAST(ERROR_MESSAGE() AS VARCHAR(1000))
END CATCH
	SET @SQL = ' ALTER DATABASE ' + @DbName + ' SET MULTI_USER ' + @CRLF
PRINT @SQL
	EXEC (@SQL)
END
ELSE
BEGIN
	PRINT 'Backup File Not Found!'
	PRINT 'Result = ' + @result + @CRLF + @fileName
END
