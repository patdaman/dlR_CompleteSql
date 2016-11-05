USE master;
SET NOCOUNT ON;

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
VALUES ('S:\SG-AZ-APP-001\XifinLIS\', 'XifinLIS')
	, ('S:\SG-AZ-APP-001\SGNL_LIS\', 'SGNL_LIS')
	, ('S:\SG-AZ-APP-001\SGNL_INTERNAL\', 'SGNL_INTERNAL')
	, ('S:\SG-AZ-APP-001\SGNL_FINANCE\', 'SGNL_FINANCE')
	, ('S:\SG-AZ-APP-001\SGNL_WAREHOUSE\', 'SGNL_WAREHOUSE');

DECLARE @ExecuteRestore BIT
DECLARE @MachineName	VARCHAR(128)
DECLARE @MapDrive 		VARCHAR(256)

/* MachineName is the machine being restored from */
SET @MachineName = COALESCE(@MachineName,'SG-AZ-APP-001')
/* If set to 0, all actions will be printed and not executed */
/* If set to 1, all databases will be restored */
SET @ExecuteRestore = 1

/* MachineName is the machine that you want to restore from */
/* to only restore from the same machine that saved the backup */
/* , uncomment the next line. */
-- SET @MachineName = CONVERT(VARCHAR(128), SERVERPROPERTY('MachineName'))

/* ----------------------------------- */
/* -------- Enable xp_cmdshell ------- */
/* ----------------------------------- */
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell',1
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
END CATCH

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
DECLARE @previousFileDate VARCHAR(20) -- used for file name
DECLARE @fileDate VARCHAR(20) -- used for file name
DECLARE @SQL VARCHAR(MAX)
DECLARE @result INT

-- specify filename format
SELECT @fileDate = LEFT(CONVERT(VARCHAR(20),GETDATE(),20), 10)
SELECT @previousFileDate = LEFT(CONVERT(VARCHAR(20),DATEADD(dd,-1,GETDATE()),20), 10)
 
DECLARE db_cursor CURSOR FOR  
SELECT bak.DbName, bak.BACKUP_PATH
FROM #BACKUP_SETTINGS bak

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name, @path   

WHILE @@FETCH_STATUS = 0   
BEGIN --> 1
	SET @SQL = ' USE ' + @name
		+ ';' + @CRLF

	SET @SQL = @SQL + 
		' UPDATE #BACKUP_SETTINGS
		SET MDF = (
					SELECT TOP 1 physical_name
					FROM sys.database_files
					WHERE RIGHT(RTRIM(physical_name),3) = ''mdf''
					);
	UPDATE #BACKUP_SETTINGS
		SET LDF = (
					SELECT TOP 1 physical_name
					FROM sys.database_files
					WHERE RIGHT(RTRIM(physical_name),3) = ''ldf''
					); '
	PRINT @SQL
	IF @ExecuteRestore = 1
		EXEC (@SQL);

	SELECT TOP 1 @mdf = MDF, @ldf = LDF
	FROM #BACKUP_SETTINGS
	WHERE DbName = @name

    SET @fileName = @path + @fileDate + '_' + @MachineName + '_' + @name + '.bak'
PRINT 'Looking for file: ' + @fileName + @CRLF
	EXEC master.dbo.xp_fileexist @fileName, @result OUTPUT
	IF (@result <> 1)
	BEGIN
		SET @fileName = @path + @previousFileDate + '_' + @MachineName + '_' + @name + '.bak'
		PRINT 'Looking for file: ' + @fileName + @CRLF
	END

	EXEC master.dbo.xp_fileexist @fileName, @result OUTPUT
	IF (@result = 1)
	BEGIN
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
			+ ' SET SINGLE_USER WITH ' + @CRLF
			+ ' ROLLBACK IMMEDIATE; ' + @CRLF

PRINT @SQL
		 IF @ExecuteRestore = 1
			EXEC (@SQL)

		----Restore Database
		SET @SQL = ' RESTORE DATABASE ' + @name + @CRLF
			+ ' FROM DISK = ''' + @fileName + '''' + @CRLF
			+ ' WITH REPLACE ' + @CRLF
			+ '		, RECOVERY ' + @CRLF
			+ ' 	, MOVE ''' + @name + ''' TO ''' + @mdf + ''' ' + @CRLF
			+ ' 	, MOVE ''' + @name + '_log'' TO ''' + @ldf + ''' ' + @CRLF
PRINT @SQL
		 IF @ExecuteRestore = 1
		 	EXEC (@SQL)

		/*If there is no error in statement before database will be in multiuser
		mode.
		If error occurs please execute following command it will convert
		database in multi user.*/
		SET @SQL = ' ALTER DATABASE ' + @name + ' SET MULTI_USER '
	END
	ELSE
		PRINT 'No File found to restore'
    FETCH NEXT FROM db_cursor INTO @name, @path
END --< 1 
 
CLOSE db_cursor   
DEALLOCATE db_cursor

IF OBJECT_ID('tempdb..#BACKUP_SETTINGS') IS NOT NULL
	DROP TABLE #BACKUP_SETTINGS

IF COALESCE(@MapDrive,'') <> ''
BEGIN
	BEGIN TRY
		/* ----------------------------------- */
		/* ----- Delete the mapped drive ----- */
		/* ----------------------------------- */
		EXEC XP_CMDSHELL 'net use S: /delete'

		/* ----------------------------------- */
		/* ----- Disable xp_cmdshell ----- */
		/* ----------------------------------- */
		EXEC sp_configure 'show advanced options', 1;
		RECONFIGURE;
		EXEC sp_configure 'xp_cmdshell',0;
		RECONFIGURE;
	END TRY
	BEGIN CATCH
		SET @ErrorMessage = 'Network drive could not be deleted.' + @CRLF
		+ 'Error Number: ' + ERROR_NUMBER() + @CRLF 
		+ ERROR_MESSAGE()
	IF @ErrorMessage NOT LIKE '%The local device name is already in use.%'
		BEGIN
			RAISERROR(@ErrorMessage, 16, 1)
			RETURN
		END
	END CATCH
END

