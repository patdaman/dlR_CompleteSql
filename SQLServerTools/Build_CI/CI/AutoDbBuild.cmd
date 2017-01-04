@ECHO OFF

SET ProjectName=%1
SET ProjectPath=%2
SET Flavor=%3
SET Build=%4
SET OutputDir=%ProjectPath%\bin\Output

SET ScriptPath=%~dp0
SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"
SET "MSBuild.exe=%ProgramFiles(x86)%\MSBuild\14.0\Bin\MSBuild.exe"

ECHO Clean Project
@ECHO ON
"%MSBuild.exe%" "%ProjectPath:"=%\%ProjectName:"=%.sqlproj" /p:Configuration=%Flavor% /p:Flavor=%Flavor% /t:Clean >> %LogOutputDir%\Clean_%DbName%_%dt%.txt
@ECHO OFF
ECHO End Clean Project

ECHO Project Build
@ECHO ON
"%MSBuild.exe%" "%ProjectPath:"=%\%ProjectName:"=%.sqlproj" /t:Build /p:Configuration=%Flavor% /p:Flavor=%Flavor% >> %LogOutputDir%\Build_%DbName%_%dt%.txt
@ECHO OFF
ECHO End Project Build
@ECHO OFF
