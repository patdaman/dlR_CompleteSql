
CREATE USER [apiTest]
		FOR LOGIN [apiTest]
		WITH DEFAULT_SCHEMA = dbo;
CREATE USER [SGNL\pdelosreyes]
		FOR LOGIN [SGNL\pdelosreyes]
		WITH DEFAULT_SCHEMA = dbo;
CREATE USER [SGNL\ehumphrey]
		FOR LOGIN [SGNL\ehumphrey]
		WITH DEFAULT_SCHEMA = dbo;
CREATE USER [SGNL\dtorres]
		FOR LOGIN [SGNL\dtorres]
		WITH DEFAULT_SCHEMA = dbo;
CREATE USER [SGNL\rphilavanh]
		FOR LOGIN [SGNL\rphilavanh]
		WITH DEFAULT_SCHEMA = dbo;
CREATE USER [SGNL\developers]
		FOR LOGIN [SGNL\developers]
		WITH DEFAULT_SCHEMA = dbo;

EXEC sp_addrolemember 'db_owner', 'SGNL\developers';
EXEC sp_addrolemember 'db_owner', 'SGNL\DbProdAdmin';
EXEC sp_addrolemember 'db_owner', 'SGNL\dtorres';
--EXEC sp_addrolemember 'db_owner', 'ssur';
EXEC sp_addrolemember 'db_owner', 'SGNL\rphilavanh';
EXEC sp_addrolemember 'db_owner', 'SGNL\pdelosreyes';
EXEC sp_addrolemember 'db_owner', 'SGNL\ehumphrey';

EXEC sp_addrolemember N'db_executor', N'apiTest';
EXEC sp_addrolemember N'db_executor', N'SGNL\DbProdModifier';

EXEC sp_addrolemember N'db_datawriter', N'apiTest';
EXEC sp_addrolemember N'db_datawriter', N'SGNL\DbProdModifier';

EXEC sp_addrolemember N'db_datareader', N'apiTest';
EXEC sp_addrolemember N'db_datareader', N'SGNL\DbProdReader';