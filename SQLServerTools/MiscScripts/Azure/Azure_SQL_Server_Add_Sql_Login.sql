-- *********************************************
-- Title: Default Azure SQL User Setup - DEV
-- Instructions: Run the first section on the 
--	'master' database only.  Then run the
--	second section on Each Database you 
--	intend to start with default DEV permissions
-- *********************************************
	-- *** Master Database
		CREATE login [signalAnalytics]
			WITH PASSWORD = 'LtRWhy!o@!MdhKnKG12HPlt+T';
		CREATE USER [signalAnalytics]
			FOR LOGIN [signalAnalytics]
			WITH DEFAULT_SCHEMA = dbo;
		EXEC sp_addrolemember 'db_datareader', 'signalAnalytics';

	-- *** SGNL_ANALYTICS Database
		CREATE USER [signalAnalytics]
		FOR LOGIN [signalAnalytics]
			WITH DEFAULT_SCHEMA = dbo;
		EXEC sp_addrolemember 'db_datareader', 'signalAnalytics';