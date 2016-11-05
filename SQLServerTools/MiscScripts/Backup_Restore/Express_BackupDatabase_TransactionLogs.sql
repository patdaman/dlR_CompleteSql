SET NOCOUNT ON
DECLARE @ext			VARCHAR(10)
DECLARE @PATH 			VARCHAR(256)
DECLARE @USER 			VARCHAR(128)
DECLARE @PASSWORD		VARCHAR(128)
DECLARE @MachineName	VARCHAR(128)
DECLARE @Print			CHAR
DECLARE @Execute		CHAR

/* ----------------------------------- */
/* ------ Configuration Section ------ */
/* ----------------------------------- */
SET @MachineName = CONVERT(VARCHAR(128), SERVERPROPERTY('MachineName'));
/* Dir path to save backup */
SET @PATH = '<PATH>'
SET @USER = '<USER>'
SET @DbName = '<DBNAME>'
/* SQL special chars require surrounded by quotes (") */
SET @PASSWORD = N'<PASSWORD>'
SET @ext = '.bak'
SET @Print = 1
SET @Execute = 0

/* ----------------------------------- */
/* --- Support Multiple Databases ---- */
/* -- Add Path, DbName to Temp table - */
/* ----------------------------------- */
IF OBJECT_ID('tempdb..#BACKUP_SETTINGS') IS NOT NULL
	DROP TABLE #BACKUP_SETTINGS;
CREATE TABLE #BACKUP_SETTINGS
(	BACKUP_PATH VARCHAR(256)
	, DbName sysname
	, MDF	VARCHAR(128)
	, LDF	VARCHAR(128)
);

INSERT INTO #BACKUP_SETTINGS (BACKUP_PATH, DbName)
VALUES (@PATH, @DbName)
	--('\\SG-CA01-DVM-004\...','SampleDb')

;
/* ----------------------------------- */
/* ---- End Configuration Section ---- */
/* ----------------------------------- */

/* ----------------------------------- */
/* ----- Create the mapped drive ----- */
/* ----------------------------------- */
DECLARE @CRLF			VARCHAR(2)
DECLARE @COMMAND		VARCHAR(4000)
DECLARE @ErrorMessage	VARCHAR(500)

SELECT @CRLF = CHAR(13) + CHAR(10)
BEGIN TRY
	SET @COMMAND = 'EXEC XP_CMDSHELL ''net use S: ' + @PATH + ' "' + @PASSWORD + '" /USER:' + @USER + ' /persistent:no'' '
	IF @Print = 1
		PRINT @COMMAND
	IF @Execute = 1
		EXEC (@COMMAND)
END TRY
BEGIN CATCH
	SET @ErrorMessage = 'Network drive could not be mapped.' + @CRLF
		+ 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(128)) + @CRLF 
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
-- DECLARE @path VARCHAR(256) -- path for backup files  
DECLARE @mdf	VARCHAR(256)
DECLARE @ldf	VARCHAR(256)
DECLARE @fileName VARCHAR(256) -- filename for backup  
DECLARE @logFileName sysname
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
		+ ';' + @CRLF

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
		+ ' 		FROM sys.database_files ' + @CRLF
		+ ' 		WHERE RIGHT(RTRIM(physical_name),3) = ''ldf'' ' + @CRLF
		+ ' 		);' + @CRLF
IF @Print = 1
	PRINT @SQL
	EXEC (@SQL)

	SELECT TOP 1 @mdf = MDF, @ldf = LDF
		, @path = BACKUP_PATH
	FROM #BACKUP_SETTINGS
	WHERE DbName = @name
	IF RIGHT(@path,1)<>'\'
		SET @path = @path + '\'
	SET @fileName = @path + @fileDate + '_' + @MachineName + '_' + @name + @ext		/* '.bak' */
	SET @DESCR = 'Full Backup of ' + @name + ' Database on ' + @fileDate
	SET @logFileName = @path + @fileDate + '_' + @MachineName + '_' + @name + '_log.bak'

	IF (((
		SELECT DATENAME(WEEKDAY, GETDATE())) = 'Sunday')
			AND (CAST(GETDATE() AS TIME) < CAST('01:00:00' AS TIME))
		)
	BEGIN --> 2

		BACKUP LOG @name 
			TO  DISK = @logFileName

		SET @SQL = ' USE ' + @name + '; ' + @CRLF
IF @Print = 1
	PRINT @SQL	
IF @Execute = 1
	EXEC (@SQL)

		-- Truncate the log by changing the database recovery model to SIMPLE.
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
		+ ' SET RECOVERY SIMPLE; ' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
	EXEC (@SQL)

		SET @SQL = ' USE ' + @name + ';' + @CRLF
		SET @SQL = @SQL 
			+ ' DECLARE @db_filename VARCHAR(128) ' + @CRLF
			+ ' SELECT @db_filename = name ' + @CRLF
			+ ' FROM sys.database_files ' + @CRLF
			+ ' WHERE RIGHT(RTRIM(name),3) <> ''log''; ' + @CRLF

		SET @SQL = @SQL + ' DBCC SHRINKFILE (@db_filename, TRUNCATEONLY); ' + @CRLF
IF @Print = 1
	PRINT @SQL	
IF @Execute = 1
	EXEC (@SQL)

		SET @SQL = ' USE ' + @name + ';' + @CRLF
		SET @SQL = @SQL 
			+ ' DECLARE @log_filename VARCHAR(128) ' + @CRLF
			+ ' SELECT @log_filename = name ' + @CRLF
			+ ' FROM sys.database_files ' + @CRLF
			+ ' WHERE RIGHT(RTRIM(name),3) = ''log''; ' + @CRLF

		SET @SQL = @SQL + ' DBCC SHRINKFILE (@log_filename, 3, TRUNCATEONLY); ' + @CRLF
IF @Print = 1
	PRINT @SQL	
IF @Execute = 1
	EXEC (@SQL)

		-- Reset the database recovery model.
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
			+ ' SET RECOVERY FULL; ' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
	EXEC (@SQL)

	SET @SQL = 'BACKUP DATABASE ' + @name + ' TO DISK = ''' + @fileName + '''' + @CRLF
				+ '	WITH FORMAT ' + @CRLF
				+ '		, NAME = ''' + @DESCR + '''' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
		BACKUP DATABASE @name TO DISK = @fileName
		WITH FORMAT
			, NAME = @DESCR

	END --< 2
	ELSE
	BEGIN
		IF (CAST(GETDATE() AS TIME) < CAST('01:00:00' AS TIME))
		BEGIN --> Once per day
			SET @SQL = 'BACKUP DATABASE ' + @name + ' TO DISK = ''' + @fileName + '''' + @CRLF
				+ '	WITH FORMAT ' + @CRLF
				+ ' , NAME = ''' + @DESCR + '''' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
			BACKUP DATABASE @name TO DISK = @fileName 
				WITH FORMAT
				, NAME = @DESCR
IF @Print <> 1
	PRINT ('Full Database Backup of ' + CAST(@name AS VARCHAR(128)) + ' completed.')
		END --< 
	SET @SQL = 'BACKUP LOG ' + @name + ' TO DISK = ''' + @logfileName + '''' + @CRLF
				+ '	WITH FORMAT ' + @CRLF
				+ '		, NAME = ''' + @DESCR + '''' + @CRLF
				+ '		COPY_ONLY ' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
		BACKUP LOG @name TO DISK = @logFileName
			WITH FORMAT
			, NAME = @DESCR
			, COPY_ONLY

		USE master;

		-- Reset the database recovery model.
		SET @SQL = ' ALTER DATABASE ' + @name + @CRLF
			+ ' SET RECOVERY FULL; ' + @CRLF
IF @Print = 1
	PRINT @SQL
IF @Execute = 1
	EXEC (@SQL)

	END --> 3
 
    FETCH NEXT FROM db_cursor INTO @name   
END --< 1 
 
CLOSE db_cursor   
DEALLOCATE db_cursor
DROP TABLE #BACKUP_SETTINGS

		