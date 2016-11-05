@ECHO OFF

SET "Source_Dir=..\"
SET SqlPackage="C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"

for /f "delims=" %%a in ('dir %source_Dir%XIFIN_LIS\Snapshots\*.dacpac /b /on') DO SET "XifinLIS_dacpac=%%a"
for /f "delims=" %%a in ('dir %source_Dir%SGNL_LIS\Snapshots\*.dacpac /b /on') DO SET "SGNL_LIS_dacpac=%%a"
for /f "delims=" %%a in ('dir %source_Dir%SGNL_INTERNAL\Snapshots\*.dacpac /b /on') DO SET "SGNL_INTERNAL_dacpac=%%a"
for /f "delims=" %%a in ('dir %source_Dir%SGNL_FINANCE\Snapshots\*.dacpac /b /on') DO SET "SGNL_FINANCE_dacpac=%%a"
for /f "delims=" %%a in ('dir %source_Dir%SGNL_WAREHOUSE\Snapshots\*.dacpac /b /on') DO SET "SGNL_WAREHOUSE_dacpac=%%a"

ECHO ******************************************
ECHO ***** Options:        ********************
ECHO *****      LOCALHOST  ********************
ECHO *****      STAGING    ********************
ECHO *****      BETA       ********************
ECHO *****      BETA2      ********************
ECHO *****      PROD_MIRROR********************
ECHO *****      PRODUCTION ********************
ECHO *****      P1 (Old Production) ***********

SET /p deployment="Where would you like to publish?"

REM *******************************************
REM ******   Handle Case Issues   *************

IF %deployment%==localhost (
	SET "deployment=LOCALHOST"
)
IF %deployment%==Localhost (
	SET "deployment=LOCALHOST"
)
IF %deployment%==Beta (
	SET "deployment=BETA"
)
IF %deployment%==beta (
	SET "deployment=BETA"
)
IF %deployment%==Beta2 (
	SET "deployment=BETA2"
)
IF %deployment%==beta2 (
	SET "deployment=BETA2"
)
IF %deployment%==Staging (
	SET "deployment=STAGING"
)
IF %deployment%==staging (
	SET "deployment=STAGING"
)
IF %deployment%==Production (
	SET "deployment=PRODUCTION"
)
IF %deployment%==production (
	SET "deployment=PRODUCTION"
)
IF %deployment%==prod_mirror (
	SET "deployment=PROD_MIRROR"
)
IF %deployment%==Prod_Mirror (
	SET "deployment=PROD_MIRROR"
)
IF %deployment%==p1 (
	SET "deployment=P1"
)

REM *******************************************

IF %deployment%==PRODUCTION (
	SET "machineName=SG-AZ-APP-001"
)

IF %deployment%==P1 (
	SET "machineName=SG-AZ-SV-001"
)

IF %deployment%==STAGING (
	SET "machineName=SG-AZDEV-SV-001"
)

IF %deployment%==BETA (
	SET "machineName=SG-CA01-DVM-002"
)

IF %deployment%==BETA2 (
	SET "machineName=SG-CA01-DVM-002\BETA,51443"
)

IF %deployment%==LOCALHOST (
	SET "machineName=localhost"
)

IF %deployment%==PROD_MIRROR (
	SET "machineName=SG-CA01-DVM-004\PRODUCTIONMIRROR,51443"
)

SET /p backup="Would you like to back up the DB's first? y/n: "
IF %backup%==Y (
	SET "backup=y"
)

IF %backup%==y (
	ECHO Backing Up Databases to NAS
	ECHO \\SG-CA01-NAS-001\Department\Shared_IS\SoftwareDevelopment\Releases\InformaticsDb\Backups
	sqlcmd -S%machineName% -i Backup\BackupToNas.sql -o Backup\BackupReport.txt
	IF errorlevel 1 goto ErrorStop
	ECHO Backup successful
)

>nul 2>nul dir /a-d "PreDeployScripts\*.sql" && (
	@(
	ECHO USE XifinLIS
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_LIS
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_INTERNAL
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_FINANCE
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_WAREHOUSE
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO -- Start Pre Deployment
	ECHO -- ********************
	ECHO.
	)>"PreDeployScriptsCombined.sql"
	ECHO Combining Pre Deployment Scripts into one transaction
	for /f "tokens=*" %%f in ('dir /b PreDeployScripts\*.sql ^| sort') do (
	type "PreDeployScripts\%%f"
	ECHO.
	)>> PreDeployScriptsCombined.sql
	@(
	ECHO.
	ECHO -- ********************
	ECHO USE XifinLIS
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_LIS
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_INTERNAL
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_FINANCE
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_WAREHOUSE
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	)>>"PreDeployScriptsCombined.sql"
	SET "preDeploy=y"
) || (SET "preDeploy=n")

ECHO An update script and deployment report will be created.
SET /p publish="Would you also like to Publish these databases? y/n: "
IF %publish%==Y (
	SET "publish=y"
)
IF NOT %publish%==y (
	goto :skipPublish
)

SET /p deployScripts="Would you like to run pre/post deployment scripts? y/n: "
IF %deployScripts%==Y (
	SET "preDeploy=y"
	SET "deployScripts=y"
)


REM	SET /p singleTransaction="Run the publish in a single transaction? y/n: "

REM	IF %singleTransaction%==Y (
REM		SET "singleTransaction=y"
REM	)

SET "singleTransaction=n"


IF %singleTransaction%==y (
	SET "deployScripts=n"
	SET "publish=n"
)
IF %deployScripts%==y (
	IF %preDeploy%==y (
		sqlcmd -E -S%machineName% -i"PreDeployScriptsCombined.sql" -o"PreDeploymentReport.txt"
		IF errorlevel 1 goto ErrorStop
	)
)

:skipPublish

REM ********* XifinLIS ************************

IF NOT %publish%==y (
%SqlPackage% /Action:Script /SourceFile:%Source_Dir%XIFIN_LIS\Snapshots\%XifinLIS_dacpac%  /Profile:%Source_Dir%XIFIN_LIS\XIFIN_LIS.%deployment%.publish.xml /OutputPath:UpdateScripts\XIFIN_LIS-%deployment%.sql /of:True
)

%SqlPackage% /Action:DeployReport  /SourceFile:%Source_Dir%XIFIN_LIS\Snapshots\%XifinLIS_dacpac% /Profile:%Source_Dir%XIFIN_LIS\XIFIN_LIS.%deployment%.publish.xml /OutputPath:DeployReports\XifinLIS-%deployment%.xml

IF %publish%==y (
%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%XIFIN_LIS\Snapshots\%XifinLIS_dacpac%  /Profile:%Source_Dir%XIFIN_LIS\XIFIN_LIS.%deployment%.publish.xml
)

REM ********* SGNL_LIS ************************

IF NOT %publish%==y (
%SqlPackage% /Action:Script /SourceFile:%Source_Dir%SGNL_LIS\Snapshots\%SGNL_LIS_dacpac%  /Profile:%Source_Dir%SGNL_LIS\SGNL_LIS.%deployment%.publish.xml /OutputPath:UpdateScripts\SGNL_LIS-%deployment%.sql /of:True
)

%SqlPackage% /Action:DeployReport  /SourceFile:%Source_Dir%SGNL_LIS\Snapshots\%SGNL_LIS_dacpac% /Profile:%Source_Dir%SGNL_LIS\SGNL_LIS.%deployment%.publish.xml /OutputPath:DeployReports\SGNL_LIS-%deployment%.xml

IF %publish%==y (
%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%SGNL_LIS\Snapshots\%SGNL_LIS_dacpac%  /Profile:%Source_Dir%SGNL_LIS\SGNL_LIS.%deployment%.publish.xml
)

REM ********** SGNL_INTERNAL ******************

IF NOT %publish%==y (
%SqlPackage% /Action:Script /SourceFile:%Source_Dir%SGNL_INTERNAL\Snapshots\%SGNL_INTERNAL_dacpac%  /Profile:%Source_Dir%SGNL_INTERNAL\SGNL_INTERNAL.%deployment%.publish.xml /OutputPath:UpdateScripts\SGNL_INTERNAL-%deployment%.sql /of:True
)

%SqlPackage% /Action:DeployReport  /SourceFile:%Source_Dir%SGNL_INTERNAL\Snapshots\%SGNL_INTERNAL_dacpac% /Profile:%Source_Dir%SGNL_INTERNAL\SGNL_INTERNAL.%deployment%.publish.xml /OutputPath:DeployReports\SGNL_INTERNAL-%deployment%.xml

IF %publish%==y (
	%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%SGNL_INTERNAL\Snapshots\%SGNL_INTERNAL_dacpac%  /Profile:%Source_Dir%SGNL_INTERNAL\SGNL_INTERNAL.%deployment%.publish.xml
)

REM *********** SGNL_FINANCE ******************

IF NOT %publish%==y (
%SqlPackage% /Action:Script /SourceFile:%Source_Dir%SGNL_FINANCE\Snapshots\%SGNL_FINANCE_dacpac%  /Profile:%Source_Dir%SGNL_FINANCE\SGNL_FINANCE.%deployment%.publish.xml /OutputPath:UpdateScripts\SGNL_FINANCE-%deployment%.sql /of:True
)

%SqlPackage% /Action:DeployReport  /SourceFile:%Source_Dir%SGNL_FINANCE\Snapshots\%SGNL_FINANCE_dacpac% /Profile:%Source_Dir%SGNL_FINANCE\SGNL_FINANCE.%deployment%.publish.xml /OutputPath:DeployReports\SGNL_FINANCE-%deployment%.xml

IF %publish%==y (
	%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%SGNL_FINANCE\Snapshots\%SGNL_FINANCE_dacpac%  /Profile:%Source_Dir%SGNL_FINANCE\SGNL_FINANCE.%deployment%.publish.xml
)

REM ************ SGNL_WAREHOUSE ***************
IF NOT %publish%==y (
%SqlPackage% /Action:Script /SourceFile:%Source_Dir%SGNL_WAREHOUSE\Snapshots\%SGNL_WAREHOUSE_dacpac%  /Profile:%Source_Dir%SGNL_WAREHOUSE\SGNL_WAREHOUSE.%deployment%.publish.xml /OutputPath:UpdateScripts\SGNL_WAREHOUSE-%deployment%.sql /of:True
)

%SqlPackage% /Action:DeployReport  /SourceFile:%Source_Dir%SGNL_WAREHOUSE\Snapshots\%SGNL_WAREHOUSE_dacpac% /Profile:%Source_Dir%SGNL_WAREHOUSE\SGNL_WAREHOUSE.%deployment%.publish.xml /OutputPath:DeployReports\SGNL_WAREHOUSE-%deployment%.xml

IF %publish%==y (
	%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%SGNL_WAREHOUSE\Snapshots\%SGNL_WAREHOUSE_dacpac%  /Profile:%Source_Dir%SGNL_WAREHOUSE\SGNL_WAREHOUSE.%deployment%.publish.xml 
)

>nul 2>nul dir /a-d "PostDeployScripts\*.sql" && (
	@(
	ECHO USE XifinLIS
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_LIS
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_INTERNAL
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_FINANCE
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_WAREHOUSE
	ECHO GO
	ECHO DISABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO -- Start Post Deployment
	ECHO -- *********************
	ECHO.
	)>"PostDeployScriptsCombined.sql"
	ECHO Combining Post Deployment Scripts into one transaction
	for /f "tokens=*" %%f in ('dir /b PostDeployScripts\*.sql ^| sort') do (
	type "PostDeployScripts\%%f"
	ECHO.
	)>> PostDeployScriptsCombined.sql
	@(
	ECHO.
	ECHO -- *********************
	ECHO GO
	ECHO USE XifinLIS
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_LIS
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_INTERNAL
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_FINANCE
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	ECHO USE SGNL_WAREHOUSE
	ECHO GO
	ECHO ENABLE TRIGGER ALL ON DATABASE
	ECHO GO
	)>>"PostDeployScriptsCombined.sql"
	SET "postDeploy=y"
) || (SET "postDeploy=n")

IF %deployScripts%==y (
	IF %postDeploy%==y (
		ECHO Running combined Post Deployment Script
		sqlcmd -E -S%machineName% -i"PostDeployScriptsCombined.sql" -o"PostDeploymentReport.txt"
		IF errorlevel 1 goto ErrorStop
		PAUSE
	)
)


@(
ECHO -- Start One Big Script for Update
ECHO -- ************************************
ECHO.
ECHO --)>"MasterUpdateScript.sql"

IF %preDeploy%==y (
	copy /b "PreDeployScriptsCombined.sql">>"MasterUpdateScript.sql"
)

for /f "tokens=*" %%f in ('dir /b UpdateScripts\*%deployment%*.sql ^| sort') do (
type "UpdateScripts\%%f"
ECHO.
)>>"MasterUpdateScript.sql"

IF %postDeploy%==y (
	type "PostDeployScriptsCombined.sql">>"MasterUpdateScript.sql""
)

@(
ECHO.
ECHO -- End Master Update Script
ECHO -- ************************
ECHO GO
)>> MasterUpdateScript.sql

@setlocal enabledelayedexpansion

@set "BOMFILE=MasterUpdateScript.sql"

@for /F %%a in (%BOMFILE%) do @set bom=%%a

@for /F "tokens=*" %%a in (%1) do @(
	@set line=%%a
	@set line=!line:%bom%=!
	@echo !line!
)

IF %singleTransaction%==y (
	ECHO Running Transactional Update Script
	SET "fullPath=%~dp0"
	cd "Program Files"\"Microsoft SQL Server"\110\Tools\Binn\
	sqlcmd -E -S%machineName% -i"%fullPath%MasterUpdateScript.sql" -o"%fullPath%PostDeploymentReport.txt"
	IF errorlevel 1 goto ErrorStop
)

	ECHO Finished Updating
	ECHO Open Post Deployment Report for details
	PAUSE
)

goto :eof

:ErrorStop
ECHO An error occured. Process stopped.
ECHO Please read Report files in corresponding directory for details.
PAUSE
