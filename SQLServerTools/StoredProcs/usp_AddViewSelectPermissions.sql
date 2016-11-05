
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-30
-- Description:	Add DB role for select of all User Defined Views in the Database Supplied
-- =============================================
CREATE PROCEDURE [dbo].[usp_AddViewSelectPermissions] 

	@ViewReader		VARCHAR(128)
	, @Database		VARCHAR(128)
	, @User			VARCHAR(128)

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Statement		VARCHAR(MAX)
	DECLARE @ErrorMessage	VARCHAR(MAX)

	SET @ViewReader = COALESCE(@ViewReader, 'db_viewreader')
	SET @Database = COALESCE(@Database, 'SGNL_WAREHOUSE')
	SET @User = COALESCE(@User, '')

	IF LEFT(@Database, 1) = '['
		SET @Database = RIGHT(@Database, LEN(@Database) -1)
	IF RIGHT(@Database, 1) = ']'
		SET @Database = LEFT(@Database, LEN(@Database) -1)

	IF LEFT(@User, 1) = '['
		SET @User = RIGHT(@User, LEN(@User) -1)
	IF RIGHT(@User, 1) = ']'
		SET @User = LEFT(@User, LEN(@User) -1)

	IF (DATABASE_PRINCIPAL_ID(@ViewReader) IS NULL)
	BEGIN
		SET @Statement = 'CREATE ROLE ' + @ViewReader
		EXEC(@Statement)
	END

	IF (DATABASE_PRINCIPAL_ID(@ViewReader) IS NULL)
	BEGIN
		SET @ErrorMessage = 'Could not create ''db_viewreader'' database role.' + CHAR(13) + CHAR(10) + 'Run with user that possesses admin rights.'
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	END

	ELSE BEGIN
		DECLARE GrantCursor CURSOR LOCAL FOR
		SELECT 'GRANT SELECT ON ' + 
				  QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + 
			  ' TO ' + @ViewReader + ';'
		FROM sys.views
		WHERE is_ms_shipped = 0

		OPEN GrantCursor

		FETCH NEXT FROM GrantCursor INTO @Statement
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'USE [' + @Database + ']'
			PRINT 'GO'
			PRINT @Statement

			EXEC ('USE [' + @Database + ']')
			EXEC (@Statement)
			FETCH NEXT FROM GrantCursor INTO @Statement
		END
	END

	IF COALESCE(@User, '') <> ''
		EXEC sp_addrolemember @ViewReader, @User
END