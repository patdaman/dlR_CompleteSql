@ECHO OFF
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
SET dt=%mydate%_%mytime: =%

SET DbName=%1
SET DbInstance=%2
SET DbBackupPath=%3
SET MachineName=%4
SET LanUser=%5
REM SET LanUser=%whoami%
SET LanPassword=%6
SET LogOutputDir=Logs\
REM SET DbBackupPath=C:\Temp

ECHO SQLCMD -S "%DbInstance:"=%" -d master -i Sql\AutoDbRestore.sql -o %LogOutputDir:"=%\Restore_%DbName:"=%_%dt%.txt -v DbName="%DbName:"=%" -v MachineName="%MachineName:"=%" -v BackupPath ="%DbBackupPath:"=%" -v LanUser="%LanUser:"=%" -v LanPassword="%LanPassword:"=%" 
@ECHO ON
start /wait cmd /c SQLCMD -S "%DbInstance:"=%" -d master -i Sql\AutoDbRestore.sql -o %LogOutputDir:"=%\Restore_%DbName:"=%_%dt%.txt -v DbName=%DbName:"=% -v MachineName=%MachineName:"=% -v BackupPath="%DbBackupPath:"=%" -v LanUser="%LanUser:"=%" -v LanPassword="%LanPassword:"=%" 
@ECHO OFF

