

DROP DATABASE SGNL_ANALYTICS_MIRROR

GO

CREATE DATABASE SGNL_ANALYTICS_MIRROR AS COPY OF [SG-AZ-SQL-001].[SGNL_ANALYTICS]

GO

DECLARE @intSanityCheck INT

SET @intSanityCheck = 0

WHILE(@intSanityCheck < 100 AND (SELECT state_desc FROM sys.databases WHERE name='SGNL_ANALYTICS_MIRROR') = 'COPYING')

BEGIN

-- wait for 10 seconds

WAITFOR DELAY '00:00:10'

SET @intSanityCheck = @intSanityCheck+1

END

GO

DECLARE @vchState VARCHAR(200)

SET @vchState = (SELECT state_desc FROM sys.databases WHERE name='SGNL_ANALYTICS_MIRROR')

IF(@vchState != 'ONLINE')

BEGIN

DECLARE @vchError VARCHAR(200)

SET @vchError = 'Failed to copy database, state = ' + @vchState

RAISERROR (@vchError, 16, 1)

END

GO