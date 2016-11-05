@ECHO OFF
SET TargetServerPath=%1
SET SourceDatabaseName=%2
SET TargetDatabaseName=%3
SET UserName=%4
SET UserPassword=%5

SET TargetServerPath=analytics-dev.database.windows.net
SET SourceDatabaseName=SGNL_ANALYTICS
SET TargetDatabaseName=SGNL_ANALYTICS_MIRROR
SET UserName=sgnlAdmin
SET UserPassword=M2OIUv3QhilheoNdJCEp

REM Drop the existing SGNL_ANALYTICS_MIRROR Database
@ECHO ON
sqlcmd -S %TargetServerPath% -U %UserName:"=% -P %UserPassword:"=% -d master -N -q"DROP DATABASE %TargetDatabaseName%"
@ECHO OFF

REM Wait for Asynchronous drop process to complete (usually a couple seconds, this waits for 11 seconds)
ping 127.0.0.1 -n 11 > nul

REM Create Database Copy on Development Server
@ECHO ON
sqlcmd -S %TargetServerPath% -U %UserName:"=% -P %UserPassword:"=% -d master -N -q"CREATE DATABASE %TargetDatabaseName% AS COPY OF [SG-AZ-SQL-001].SGNL_ANALYTICS ( SERVICE_OBJECTIVE = 'S0')"
@ECHO OFF

ping 127.0.0.1 -n 600 > nul

REM Create Api Development User
@ECHO ON
sqlcmd -S %TargetServerPath% -U %UserName:"=% -P %UserPassword:"=% -d %DatabaseName%  -N -q"CREATE USER apiTest WITH PASSWORD = 'Ap1T3st!'"
@ECHO OFF

REM Add user to the database owner role
@ECHO ON
sqlcmd -S %TargetServerPath% -U %UserName:"=% -P %UserPassword:"=% -d %DatabaseName% -N -q"EXEC sp_addrolemember N'db_owner', N'developers'"
sqlcmd -S %TargetServerPath% -U %UserName:"=% -P %UserPassword:"=% -d %DatabaseName% -N -q"EXEC sp_addrolemember N'db_owner', N'apiTest'"
@ECHO OFF