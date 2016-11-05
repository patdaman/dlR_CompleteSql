USE master
GO

CREATE TABLE #BACKUP_SETTINGS
(	BACKUP_PATH VARCHAR(256)
	, DbName sysname
)
GO

/* ----------------------------------- */
/* ------ Configuration Section ------ */
/* ----------------------------------- */
INSERT INTO #BACKUP_SETTINGS (BACKUP_PATH, DbName)
VALUES ('S:XifinLIS\', 'XifinLIS')
	, ('S:SGNL_LIS\', 'SGNL_LIS')
	, ('S:SGNL_INTERNAL\', 'SGNL_INTERNAL')
	, ('S:SGNL_FINANCE\', 'SGNL_FINANCE')
	, ('S:SGNL_WAREHOUSE\', 'SGNL_WAREHOUSE')

/* ----------------------------------- */
/* -------- Enable xp_cmdshell ------- */
/* ----------------------------------- */
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO

/* ----------------------------------- */
/* ----- Create the mapped drive ----- */
/* ----------------------------------- */
EXEC XP_CMDSHELL 'net use S: \\SG-CA01-NAS-001\Department\Shared_IS\SoftwareDevelopment\Releases\InformaticsDb\Backups 93bd62e1adFB9007a4731bf97c201e3c! /USER:SGNL\DatabaseBackup /persistent:no'

/* ************************************************************************************** */
/* ********************************* No Edits Below Here!! ****************************** */
/* ************************************************************************************** */

/* --------------------------------------------- */
/* ------------ Backup Databases --------------- */
DECLARE @name VARCHAR(50) -- database name  
DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name
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

    SET @fileName = @path + @fileDate + '_' + @name + '_Deployment_Backup.bak'
	SET @DESCR = 'Full Backup of ' + @name + ' Database on ' + @fileDate
    BACKUP DATABASE @name TO DISK = @fileName WITH FORMAT, NAME = @DESCR
 
    FETCH NEXT FROM db_cursor INTO @name   
END --< 1 
 
CLOSE db_cursor   
DEALLOCATE db_cursor
DROP TABLE #BACKUP_SETTINGS

/* ----------------------------------- */
/* ----- Delete the mapped drive ----- */
/* ----------------------------------- */
EXEC XP_CMDSHELL 'net use S: /delete'

/* ----------------------------------- */
/* ----- Disable xp_cmdshell ----- */
/* ----------------------------------- */
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',0
GO
RECONFIGURE
GO
