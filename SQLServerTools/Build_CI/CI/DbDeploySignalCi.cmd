@ECHO OFF
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
SET dt=%mydate%_%mytime: =%

@ECHO OFF
SET "Restore=%0"
SET "ProjectName=%1"
SET "ProjectPath=%2"
SET "Flavor=%3"
SET "Build=%4"
SET "DbInstance=%5"
SET "BackupPath=%6"
SET "Report=%6"
SET "Publish=%7"
SET "Backup=%8"
SET "MachineName=%9"

SET "Restore=0"
SET "ProjectName=Xifin_LIS"
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\Xifin_LIS"
SET "Flavor=SignalCi"
SET	"Build=Test"
SET	"DbInstance=SG-CA01-DVM-004\SignalCi,7433"
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"
SET	"Report=n"
SET	"Publish=y"
SET "Backup=n"
SET "DbName=XifinLIS"
SET "UserName=SGNL\developers"
SET "Role=db_owner"
SET "MachineName=SG-AZ-APP-001"
SET "LanUser=SGNL\DatabaseBackup"
SET "LanPassword=93bd62e1adFB9007a4731bf97c201e3c!"
SET "DbBackupLocation=\\SG-CA01-NAS-001\Department\Shared_IS\SoftwareDevelopment\DatabaseStaging\SG-AZ-APP-001\"

ECHO ***********************************************
ECHO ***************** XifinLIS ********************
ECHO ***********************************************
IF %Restore%==1 (
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
)

REM -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF

ECHO ***********************************************
ECHO ***************** SGNL_LIS ********************
ECHO ***********************************************
@ECHO OFF
SET ProjectName=SGNL_LIS
SET DbName=SGNL_LIS
SET ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_LIS
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%

REM -- ************************************************************** --
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
REM start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF

ECHO ***********************************************
ECHO *************** SGNL_INTERNAL *****************
ECHO ***********************************************
@ECHO OFF
SET ProjectName=SGNL_INTERNAL
SET DbName=SGNL_INTERNAL
SET ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_INTERNAL
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%

REM -- ************************************************************** --
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
REM start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF

ECHO ***********************************************
ECHO ***************** SGNL_FINANCE ****************
ECHO ***********************************************
@ECHO OFF
SET ProjectName=SGNL_FINANCE
SET DbName=SGNL_FINANCE
SET ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_FINANCE
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%

REM -- ************************************************************** --
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
REM start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF

ECHO ***********************************************
ECHO ************** SGNL_WAREHOUSE *****************
ECHO ***********************************************

@ECHO OFF
SET ProjectName=SGNL_WAREHOUSE
SET DbName=SGNL_WAREHOUSE
SET ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_WAREHOUSE
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%

REM -- ************************************************************** --
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
REM start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF

ECHO ***********************************************
ECHO ************** SGNL_ANALYTICS *****************
ECHO ***********************************************

@ECHO OFF
SET "ProjectName=SGNL_ANALYTICS"
SET DbName=SGNL_ANALYTICS
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_ANALYTICS"
SET DbBackupPath=%DbBackupLocation:"=%%DbName:"=%

ECHO !!!!SGNL_ANALYTICS SKIPPED!!!!

REM -- ************************************************************** --
ECHO Restore Database
ECHO Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO ON
REM REM start /wait cmd /c Call AutoDbRestore.cmd "%DbName%" "%DbInstance%" "%DbBackupPath%" "%MachineName%" "%LanUser%" "%LanPassword%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Update Dev Roles On Database
ECHO Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO ON
REM start /wait cmd /c Call AutoDbRoleUpdate.cmd "%DbName%" "%DbInstance%" "%Role%" "%UserName%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Clean / Build Database
ECHO Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO ON
REM start /wait cmd /c Call AutoDbBuild.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%"
@ECHO OFF
ECHO -- ************************************************************** --
ECHO Deploy Database
ECHO Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO ON
REM start /wait cmd /c Call AutoDbDeploy.cmd "%ProjectName%" "%ProjectPath%" "%Flavor%" "%Build%" "%BackupPath%" "%Report%" "%Publish%" "%Backup%"
@ECHO OFF
pause

:End