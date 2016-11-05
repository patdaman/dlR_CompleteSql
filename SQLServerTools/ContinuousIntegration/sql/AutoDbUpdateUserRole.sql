CREATE USER [$(UserName)]
		FOR LOGIN [$(UserName)]
		WITH DEFAULT_SCHEMA = dbo;

EXEC sp_addrolemember '$(Role)', '$(UserName)';
