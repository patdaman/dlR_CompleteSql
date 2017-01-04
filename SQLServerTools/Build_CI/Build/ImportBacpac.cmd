@ECHO OFF
SET ProjectPath=%~dp0

ECHO ******************************************
ECHO ***** Options:        ********************
ECHO *****      DEV		   ********************
ECHO *****      BETA       ********************
ECHO *****      PROD_MIRROR********************
ECHO *****      PRODUCTION ********************

REM		\/-- Set Up Here --\/
SET Flavor=PROD_MIRROR
SET ProjectName=SGNL_ANALYTICS
SET DateTime=_2016-07-14_2353
SET Build=_%DateTime%
SET BackupPath=\\sg-ca01-nas-001\Department\Shared_IS\SoftwareDevelopment\DatabaseStaging\Analytics-dev\SGNL_ANALYTICS\
SET DatabaseUrl=analytics-dev.database.windows.net
SET SqlUser=azureAdmin
SET Password=YiumaLHC0XOQRWEMBvqZ
REM		/\-- Set Up Here --/\

pushd "..\"
SET Source_Dir=%~dp1

IF %Flavor%==PRODUCTION (
SET "machineName=SG-AZ-APP-001"
)
IF %Flavor%==BETA (
SET "machineName=SG-CA01-DVM-002"
)
IF %Flavor%==DEV (
SET "machineName=SG-CA01-DVM-004"
)
IF %Flavor%==PROD_MIRROR (
SET "machineName=SG-CA01-DVM-004\PRODUCTIONMIRROR,51443"
)
SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"

@ECHO ON
%SqlPackage% /a:Import /tdn:%ProjectName% /tsn:%machineName% /su:%SqlUser% /sp:%Password% /SourceFile:%BackupPath%\%ProjectName%%Build%.bacpac
@ECHO OFF

pushd "%~dp0"
