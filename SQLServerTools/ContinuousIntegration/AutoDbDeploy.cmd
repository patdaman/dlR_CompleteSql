@ECHO OFF
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
SET dt=%mydate%_%mytime: =%

SET ProjectName=%1
SET ProjectPath=%2
SET Flavor=%3
SET Build=%4
SET BackupPath=%5
SET Report=%6
SET Publish=%7
SET Backup=%8
SET OutputDir=%ProjectPath:"=%\bin\Output
SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"
SET LogOutputDir=Logs\

ECHO -- ************ --
ECHO Project Deploy
@ECHO OFF
IF %Report:"=%==y (
	@ECHO ON
	%SqlPackage% /Action:DeployReport  /SourceFile:"%OutputDir:"=%\%ProjectName:"=%.dacpac" /Profile:"%ProjectPath:"=%%ProjectName:"=%.%Flavor%.publish.xml" /OutputPath:"%OutputDir:"=%\%ProjectName:"=%-%Flavor%.xml" >> %LogOutputDir%\DeployReport_%DbName:"=%_%dt%.txt
	@ECHO OFF
)
IF %Publish:"=%==y (
	@ECHO ON
	%SqlPackage% /Action:Publish /SourceFile:"%OutputDir:"=%\%ProjectName:"=%.dacpac" /Profile:"%ProjectPath:"=%\%ProjectName:"=%.%Flavor%.publish.xml" >> %LogOutputDir%\Publish_%DbName:"=%_%dt%.txt
	@ECHO OFF
)
IF %Backup:"=%==y (
@ECHO ON
	robocopy "%ProjectPath:"=%\%OutputDir:"=%" "%BackupPath:"=%" /mir /z /log+:%ProjectName:"=%_%Build:"=%.txt >> %LogOutputDir%\BuildPackageCopy_%DbName:"=%_%dt%.txt
@ECHO OFF
)
