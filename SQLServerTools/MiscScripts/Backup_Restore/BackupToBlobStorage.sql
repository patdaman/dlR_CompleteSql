USE master;

CREATE TABLE #BACKUP_SETTINGS
(	BACKUP_PATH VARCHAR(256)
	, DbName sysname
)
;

/* ----------------------------------- */
/* ------ Configuration Section ------ */
/* ----------------------------------- */
INSERT INTO #BACKUP_SETTINGS (BACKUP_PATH, DbName)
VALUES ('https://resultspx.blob.core.windows.net/dbbackups/', 'ChipDx_AffyChipDB')
	, ('https://resultspx.blob.core.windows.net/dbbackups/', 'ChipDX_ASPNET')
	, ('https://resultspx.blob.core.windows.net/dbbackups/', 'ChipDx_TumorOrigin')

/* --------------------------------------------- */
/* ------------ Backup Databases --------------- */
DECLARE @name VARCHAR(50) -- database name  
DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @userName sysname -- Backup File Writer Credential
DECLARE @DESCR VARCHAR(500)

-- specify filename format
SELECT @fileDate = LEFT(CONVERT(VARCHAR(20),GETDATE(),20), 10)
 
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name IN (SELECT DbName FROM #BACKUP_SETTINGS)

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   

WHILE @@FETCH_STATUS = 0   
BEGIN --> 1
	-- specify database backup directory
	SELECT @path = BACKUP_PATH
	FROM #BACKUP_SETTINGS
	WHERE DbName = @name

    SET @fileName = @path + @fileDate + '_' + @name + '.bak'
	SET @logFileName = @path + @fileDate + '_' + @name + '_log.bak'
	SET @DESCR = 'Full Backup of Production ' + @name + ' Database on ' + @fileDate

    BACKUP DATABASE @name 
	TO URL = @fileName 
	WITH FORMAT
		, CREDENTIAL = 'ResultsPx'
		, COPY_ONLY
		, NAME = @DESCR
		, COMPRESSION;

		--
	BACKUP LOG @name
	TO URL = @fileName
	WITH 
		CREDENTIAL = 'ResultsPx'
		, COPY_ONLY
		, COMPRESSION;
 
    FETCH NEXT FROM db_cursor INTO @name   
END --< 1 
 
CLOSE db_cursor   
DEALLOCATE db_cursor
DROP TABLE #BACKUP_SETTINGS
