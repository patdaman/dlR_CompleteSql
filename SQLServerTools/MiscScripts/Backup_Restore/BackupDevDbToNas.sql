IF OBJECT_ID('tempdb..#BACKUP_SETTINGS') IS NOT NULL
	DROP TABLE #BACKUP_SETTINGS;

CREATE TABLE #BACKUP_SETTINGS
(	BACKUP_PATH VARCHAR(256)
	, DbName sysname
	, MDF	VARCHAR(128)
	, LDF	VARCHAR(128)
);

/* ----------------------------------- */
/* ------ Configuration Section ------ */
/* ----------------------------------- */
INSERT INTO #BACKUP_SETTINGS (BACKUP_PATH, DbName)
VALUES ('S:\DevelopmentDBs\XifinLIS\', 'XifinLIS')
	, ('S:\DevelopmentDBs\SGNL_LIS\', 'SGNL_LIS')
	, ('S:\DevelopmentDBs\SGNL_INTERNAL\', 'SGNL_INTERNAL')
	, ('S:\DevelopmentDBs\SGNL_FINANCE\', 'SGNL_FINANCE')
	, ('S:\DevelopmentDBs\SGNL_WAREHOUSE\', 'SGNL_WAREHOUSE')
	;

DECLARE @MachineName	VARCHAR(128)
SET @MachineName = CONVERT(VARCHAR(128), SERVERPROPERTY('MachineName'));

/* ----------------------------------- */
/* -------- Enable xp_cmdshell ------- */
/* ----------------------------------- */
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell',1;
RECONFIGURE;

/* ----------------------------------- */
/* ----- Create the mapped drive ----- */
/* ----------------------------------- */
DECLARE @CRLF			VARCHAR(2)
DECLARE @ErrorMessage	VARCHAR(500)
SELECT @CRLF = CHAR(13) + CHAR(10)
BEGIN TRY
	EXEC XP_CMDSHELL 'net use S: \\SG-CA01-NAS-001\Department\Shared_IS\SoftwareDevelopment\DatabaseStaging 93bd62e1adFB9007a4731bf97c201e3c! /USER:SGNL\DatabaseBackup /persistent:no'
END TRY
BEGIN CATCH
	SET @ErrorMessage = 'Network drive could not be mapped.' + @CRLF
		+ 'Error Number: ' + ERROR_NUMBER() + @CRLF 
		+ ERROR_MESSAGE()
	IF @ErrorMessage NOT LIKE '%The local device name is already in use.%'
		BEGIN
			RAISERROR(@ErrorMessage, 16, 1)
			RETURN
		END
END CATCH;

/* ************************************************************************************** */
/* ********************************* No Edits Below Here!! ****************************** */
/* ************************************************************************************** */

/* --------------------------------------------- */
/* ------------ Backup Databases --------------- */
DECLARE @name VARCHAR(50) -- database name  
DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @mdf	VARCHAR(256)
DECLARE @ldf	VARCHAR(256)
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @DESCR VARCHAR(500)
DECLARE @SQL	VARCHAR(MAX)

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
	SET @SQL = ' USE ' + @name
		+ ';'

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
	EXEC (@SQL);

	SELECT TOP 1 @mdf = MDF, @ldf = LDF
		, @path = BACKUP_PATH
	FROM #BACKUP_SETTINGS
	WHERE DbName = @name
	SET @fileName = @path + @fileDate + '_' + @MachineName + '_' + @name + '.bak'
	SET @DESCR = 'Full Backup of Development ' + @name + ' Database on ' + @fileDate

	IF ((SELECT DATENAME(WEEKDAY, GETDATE())) = 'Sunday')
	BEGIN --> 2


		DECLARE @BackupFile sysname
		SET @BackupFile = @path + @fileDate + '_' + @MachineName + '_' + @name + '_log.bak'
		BACKUP LOG @name 
			TO  DISK = @BackupFile
			WITH COMPRESSION

		SET @SQL = ' USE ' + @name + '; ' + @CRLF
		PRINT @SQL	
		EXEC (@SQL)

		-- Truncate the log by changing the database recovery model to SIMPLE.
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
		+ ' SET RECOVERY SIMPLE; ' + @CRLF
		PRINT @SQL
		EXEC (@SQL)

		SET @SQL = ' USE ' + @name + ';' + @CRLF
		SET @SQL = @SQL 
			+ ' DECLARE @db_filename VARCHAR(128) ' + @CRLF
			+ ' SELECT @db_filename = name ' + @CRLF
			+ ' FROM sys.database_files ' + @CRLF
			+ ' WHERE RIGHT(RTRIM(name),3) <> ''log''; ' + @CRLF

		SET @SQL = @SQL + ' DBCC SHRINKFILE (@db_filename, TRUNCATEONLY); ' + @CRLF
		PRINT @SQL	
		EXEC (@SQL)

		SET @SQL = ' USE ' + @name + ';' + @CRLF
		SET @SQL = @SQL 
			+ ' DECLARE @log_filename VARCHAR(128) ' + @CRLF
			+ ' SELECT @log_filename = name ' + @CRLF
			+ ' FROM sys.database_files ' + @CRLF
			+ ' WHERE RIGHT(RTRIM(name),3) = ''log''; ' + @CRLF

		SET @SQL = @SQL + ' DBCC SHRINKFILE (@log_filename, 3, TRUNCATEONLY); ' + @CRLF
		PRINT @SQL	
		EXEC (@SQL)

		-- Reset the database recovery model.
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
			+ ' SET RECOVERY FULL; ' + @CRLF
		PRINT @SQL	
		EXEC (@SQL)

		BACKUP DATABASE @name TO DISK = @fileName 
		WITH FORMAT
			, NAME = @DESCR
			, COMPRESSION

		SET @SQL = ' USE MSDB; ' + @CRLF
			+ ' EXEC smart_admin.sp_backup_on_demand ' + @CRLF
			+ '		@database_name = '' + @name + '' ' + @CRLF
			+ '		, @type = ''Database'' ' + @CRLF

		PRINT @SQL	
		EXEC (@SQL)
	END --< 2
	ELSE
	BEGIN
		BACKUP DATABASE @name TO DISK = @fileName 
			WITH FORMAT
			, NAME = @DESCR
			, COPY_ONLY
			, COMPRESSION

		USE master;
	END --> 3
 
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
		