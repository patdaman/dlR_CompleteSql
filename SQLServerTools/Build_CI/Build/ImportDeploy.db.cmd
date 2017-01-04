@ECHO OFF

REM This is supposed to give me the folder name, but doesn't work ARGH!
ECHO Dagnabbit...
SET ProjectName=%~n1
ECHO %ProjectName%
SET ProjectPath=%~dp0

@echo off
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)
SET DateTime=%mydate%_%mytime%

REM **************************
REM **  User Edit Variables **
REM **************************

ECHO ******************************************
ECHO ***** Options:        ********************
ECHO *****      LOCALHOST  ********************
ECHO *****      STAGING    ********************
ECHO *****      BETA       ********************
ECHO *****      BETA2      ********************
ECHO *****      PROD_MIRROR********************
ECHO *****      PRODUCTION ********************
ECHO *****      P1 (Old Production) ***********

REM		\/-- Set Up Here --\/
SET Flavor=PROD_MIRROR
SET CONFIGURATION=RELEASE
SET TargetComputerName=SG-CA01-DVM-004
SET ProjectName=SGNL_ANALYTICS
SET Source_Dir=%~dp1
SET Script=n
SET Publish=y
SET Build=%DateTime%
SET Destination=bin\output
SET BackupPath=\\SG-CA01-NAS-001\Department\Shared_IS\SoftwareDevelopment\Releases\InformaticsDb\XifinLIS\Snapshots\%Build%
SET BlobUrl=https://developmentdb.blob.core.windows.net/analytics-backup/
REM SET BackupPath=%ProjectPath%
REM		/\-- Set Up Here --/\

REM **************************
REM * End User Edit Variables*
REM **************************

pushd "..\"
SET Build=%Build: =%
SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"

for /f "delims=" %%a in ('dir %source_Dir%%ProjectName%\%Output%\%ProjectName%.dacpac /b /on') DO SET "%ProjectName%_bacpac=%%a"

REM SET /p deployment="Where would you like to publish?"
SET deployment=%FLAVOR%

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

@ECHO ON
%SqlPackage% /a:Export /ssn:analytics-dev.database.windows.net /sdn:%ProjectName% /su:azureAdmin /sp:YiumaLHC0XOQRWEMBvqZ /tf:%BackupPath%\%ProjectName%_%Build%.bacpac

@ECHO ON
%SqlPackage% /a:Import /tdn:%ProjectName% /tsn:%machineName% /SourceFile:%BlobUrl%%ProjectName%.bacpac
@ECHO OFF

@ECHO ON
%SqlPackage% /Action:Publish /SourceFile:%Source_Dir%%ProjectName%\%Destination%\%ProjectName%.dacpac /Profile:%Source_Dir%%ProjectName%\%ProjectName%.%deployment%.publish.xml
@ECHO OFF

pushd %ProjectPath%
@ECHO ON
REM robocopy "%ProjectPath%\%Destination%" "%BackupPath%" /mir /z /log+:%ProjectName%%Build%.txt
@ECHO OFF

pushd "%~dp0"
REM pause
