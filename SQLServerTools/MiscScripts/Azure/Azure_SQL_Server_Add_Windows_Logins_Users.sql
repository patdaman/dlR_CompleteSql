-- *********************************************
-- For 'Contained Database' users in Azure SQL Server
-- *********************************************

-- Connect to desired user database
CREATE USER [prodApi] WITH PASSWORD = 'strong_password';

-- *********************************************
-- For 'Master' users in Azure SQL Server
-- *********************************************

-- connect to 'master' database
-- Lookup 'SIDS' for login
SELECT [name], [sid] 
FROM [sys].[sql_logins] 
WHERE [type_desc] = 'SQL_Login'

SELECT [name], [sid]
FROM [sys].[database_principals]
WHERE [type_desc] = 'SQL_USER'

-- Create login with corresponding 'SIDS' for login
CREATE LOGIN [prodApi]
WITH PASSWORD = <login password>,
SID = <desired login SID>


-- *********************************************
-- Title: Default Azure SQL User Setup - DEV
-- Instructions: Run the first section on the 
--	'master' database only.  Then run the
--	second section on Each Database you 
--	intend to start with default DEV permissions
-- *********************************************

	-- *** Master Database
		CREATE login [apiTest]
			WITH PASSWORD = 'LtRWhy!o@!MdhKnKG12HPlt+T';
		CREATE USER [apiTest]
			FOR LOGIN [apiTest]
			WITH DEFAULT_SCHEMA = dbo;

		CREATE login [prodApi]
			WITH PASSWORD = '';
		CREATE USER [prodApi]
			FOR LOGIN [prodApi]
			WITH DEFAULT_SCHEMA = dbo;

EXEC sp_addrolemember 'db_datareader', 'MyUser';
GO

EXEC sp_addrolemember 'db_datawriter', 'MyUser';
GO

GRANT EXECUTE ON SCHEMA :: dbo TO MyUser;

		-- *********** Patrick de los Reyes ********** --
			CREATE LOGIN pdelosReyes
				WITH PASSWORD = 'SignalG123!';
	
			CREATE USER pdelosReyes 
				FOR LOGIN pdelosReyes 
				WITH DEFAULT_SCHEMA = dbo;
		-- ****** end Patrick de los Reyes end ******* --
		-- ************* Rita Philavanh ************** --
			CREATE LOGIN rphilavanh
				WITH PASSWORD = 'Signal123!';

			CREATE USER [rphilavanh]
				FOR LOGIN [rphilavanh]
				WITH DEFAULT_SCHEMA = dbo;
		-- ********* end Rita Philavanh end ********** --
		-- ************** Erik Humphrey ************** --
			CREATE LOGIN [ehumphrey]
				WITH PASSWORD = 'Signal123!';

			CREATE USER [ehumphrey]
				FOR LOGIN [ehumphrey]
				WITH DEFAULT_SCHEMA = dbo;
		-- ********** end Erik Humphrey end ********** --
		-- ************** Sudipto Sur **************** --
			CREATE LOGIN [ssur]
				WITH PASSWORD = 'Signal123!';

			CREATE USER [ssur]
				FOR LOGIN [ssur]
				WITH DEFAULT_SCHEMA = dbo;
		-- ********** end Sudipto Sur end ************ --
		-- ************** David Torres *************** --
			CREATE LOGIN [dtorres]
				WITH PASSWORD = 'Signal123!';

			CREATE USER [dtorres]
				FOR LOGIN [dtorres]
				WITH DEFAULT_SCHEMA = dbo;
		-- ********** end David Torres end *********** --


-- *********************************************
BREAK; 
-- *********************************************
-- Title: Default Azure SQL User Setup - DEV
-- Instructions: Run the first section on the
--	master database, then the following on each
--	user database.
-- *********************************************
-- *** Each Database ***
		CREATE USER [developers]
			FROM EXTERNAL PROVIDER

		-- If above doesn't work:
		-- CREATE USER developers FOR LOGIN developers ;

		CREATE USER [DbProdAdmin] 
			FROM EXTERNAL PROVIDER;

		CREATE USER [DbProdReader] 
			FROM EXTERNAL PROVIDER;

		CREATE USER [DbProdModifier] 
			FROM EXTERNAL PROVIDER;
		
		-- prodApi user setup
		CREATE USER [prodApi]
				FOR LOGIN [prodApi]
				WITH DEFAULT_SCHEMA = dbo;
		
		-- apiTest user setup
		-- CREATE USER [apiTest] 
		--		FOR LOGIN [apiTest]
		--		WITH DEFAULT_SCHEMA = dbo;
		
		EXEC sp_addrolemember 'db_owner', 'developers';
		EXEC sp_addrolemember 'db_owner', 'DbProdAdmin';
		EXEC sp_addrolemember 'db_owner', 'dtorres';
		EXEC sp_addrolemember 'db_owner', 'rphilavanh';
		EXEC sp_addrolemember 'db_owner', 'pdelosreyes';
		EXEC sp_addrolemember 'db_owner', 'ssur';
		EXEC sp_addrolemember 'db_owner', 'ehumphrey';

		EXEC sp_addrolemember N'db_executor', N'prodApi';
		EXEC sp_addrolemember N'db_executor', N'apiTest';
		EXEC sp_addrolemember N'db_executor', N'DbProdModifier';

		EXEC sp_addrolemember N'db_datawriter', N'prodApi';
		EXEC sp_addrolemember N'db_datawriter', N'apiTest';
		EXEC sp_addrolemember N'db_datawriter', N'DbProdModifier';

		EXEC sp_addrolemember N'db_datareader', N'prodApi';
		EXEC sp_addrolemember N'db_datareader', N'apiTest';
		EXEC sp_addrolemember N'db_datareader', N'DbProdReader';

-- *** end Each Database end ***


