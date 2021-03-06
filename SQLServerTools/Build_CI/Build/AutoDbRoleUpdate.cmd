@ECHO OFF
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
SET dt=%mydate%_%mytime: =%

SET DbName=%1
SET DbInstance=%2
SET Role=%3
SET UserName=%4
REM SET DbInstance=%DbInstance:"=%

REM ****************************************************** REM
ECHO Update Dev Roles On Database
ECHO SQLCMD -S %DbInstance% -d %DbName% -i AutoDbUpdateUserRole.sql -v Role =%Role% -v UserName =%UserName% >> Logs\UpdateRoles_%DbName%_%dt%.txt
@ECHO ON
SQLCMD -S %DbInstance% -d %DbName% -i AutoDbUpdateUserRole.sql -v Role =%Role% -v UserName =%UserName% >> Logs\UpdateRoles_%DbName%_%dt%.txt
@ECHO OFF
