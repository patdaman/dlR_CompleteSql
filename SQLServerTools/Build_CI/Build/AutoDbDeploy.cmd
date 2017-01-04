@ECHO OFF

SET ProjectName=%1
SET ProjectPath=%2
SET Flavor=%3
SET Build=%4
SET BackupPath=%6
SET OutputDir=%ProjectPath%\bin\Output

SET ScriptPath=%~dp0
SET SqlPackage="%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"
SET deployment=%FLAVOR%
SET "MSBuild.exe=%ProgramFiles(x86)%\MSBuild\14.0\Bin\MSBuild.exe"

REM Clean Project
"%MSBuild.exe%" "%ProjectPath%\%ProjectName%.sqlproj" /p:Configuration=%CONFIGURATION% /t:Clean

REM 
"%MSBuild.exe%" "%ProjectPath%\%ProjectName%.sqlproj" /p:Configuration=%CONFIGURATION% /p:Flavor=%Flavor%

%SqlPackage% /Action:DeployReport  /SourceFile:%OutputDir%\%ProjectName%.dacpac /Profile:%ProjectPath%\%ProjectName%.%deployment%.publish.xml /OutputPath:%OutputDir%\%ProjectName%-%deployment%.xml

%SqlPackage% /Action:Publish /SourceFile:%OutputDir%\%ProjectName%.dacpac  /Profile:%ProjectPath%\%ProjectName%.%deployment%.publish.xml

REM robocopy "%ProjectPath%\%OutputDir%" "%BackupPath%" /mir /z /log+:%ProjectName%%Build%.txt

pushd %ScriptPath%
pause