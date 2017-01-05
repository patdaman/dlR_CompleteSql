CREATE USER [apiTest]
		FOR LOGIN [apiTest]
		WITH DEFAULT_SCHEMA = dbo;

EXEC sp_addrolemember 'db_owner', 'developers';
EXEC sp_addrolemember 'db_owner', 'DbProdAdmin';
EXEC sp_addrolemember 'db_owner', 'pdelosreyes';

EXEC sp_addrolemember N'db_executor', N'apiTest';
EXEC sp_addrolemember N'db_executor', N'DbProdModifier';

EXEC sp_addrolemember N'db_datawriter', N'apiTest';
EXEC sp_addrolemember N'db_datawriter', N'DbProdModifier';

EXEC sp_addrolemember N'db_datareader', N'apiTest';
EXEC sp_addrolemember N'db_datareader', N'DbProdReader';