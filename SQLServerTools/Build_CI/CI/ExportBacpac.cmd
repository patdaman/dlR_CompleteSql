@ECHO OFF
SET ProjectPath=%~dp0

For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)
SET DateTime=%mydate%_%mytime%

ECHO ******************************************
ECHO ***** Options:        ********************
ECHO *****      DEV		   ********************
ECHO *****      BETA       ********************
ECHO *****      PROD_MIRROR********************
ECHO *****      PRODUCTION ********************

REM		\/-- Set Up Here --\/
SET Flavor=PROD_MIRROR
SET ProjectName=SGNL_ANALYTICS
SET Build=%DateTime%
SET BackupPath=\\sg-ca01-nas-001\Department\Shared_IS\SoftwareDevelopment\DatabaseStaging\Analytics-dev\SGNL_ANALYTICS\
SET DatabaseUrl=analytics-dev.database.windows.net
SET SqlUser=azureAdmin
SET Password=YiumaLHC0XOQRWEMBvqZ
REM		/\-- Set Up Here --/\

pushd "..\"
SET Source_Dir=%~dp1

SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"

@ECHO ON
%SqlPackage% /a:Export /ssn:%DatabaseUrl% /sdn:%ProjectName% /su:%SqlUser% /sp:%Password% /tf:%BackupPath%\%ProjectName%_%Build%.bacpac

@ECHO OFF

pushd "%~dp0"
