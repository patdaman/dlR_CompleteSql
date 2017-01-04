@ECHO OFF

REM This is supposed to give me the folder name, but doesn't work ARGH!
ECHO Dagnabbit...
SET ProjectName=%~n1
ECHO %ProjectName%

REM **************************
REM **  User Edit Variables **
REM **************************

REM ** Options
REM ** DEBUG		
REM ** RELEASE		<-- Default

REM		\/-- Set Up Here --\/
SET CONFIGURATION=RELEASE
SET TargetComputerName=
SET ProjectName=
REM		/\-- Set Up Here --/\
REM **************************
REM * End User Edit Variables*
REM **************************

ECHO %USERNAME% at %Date% %Time%
ECHO Deleting all files from Output Directory

SET Destination=bin\%CONFIGURATION%
ECHO %Destination%

@ECHO ON
del /q %Destination%\*
for /d %%x in (%Destination%\*) do @rd /s /q "%%x"
@ECHO OFF
pause

REM Set the Path to MSBuild.exe
pushd "%ProgramFiles(x86)%\MSBuild\14.0\Bin"
SET MSBuild.exe=MSBuild.exe

@ECHO ON
%MSBuild.exe% "%ProjectPath%\%ProjectName%.sqlproj" /p:Configuration=%CONFIGURATION% /t:Clean
REM ECHO PROJECT CLEAN COMPLETE
@ECHO OFF
pause

@ECHO ON
REM Project being compiled and built 
REM with SlowCheetah included
%MSBuild.exe% "%ProjectPath%\%ProjectName%.csproj" /p:Configuration=%CONFIGURATION% /t:SlowCheetah /t:Compile /t:Build /p:Flavor=%CONFIGURATION%
ECHO Project Compiled 
@ECHO OFF
pause

@ECHO ON
REM Project being deployed
%MSBuild.exe% "%ProjectPath%\%ProjectName%.csproj" /p:Configuration=%CONFIGURATION% /t:Deploy /p:TargetComputerName=%TargetComputerName%
ECHO DEPLOYED
pause

@ECHO OFF

REM All Options in the SignalBuild Custom Targets
REM ****************************************************
REM /p:Configuration=%CONFIGURATION%			<-- For MSBuild Command
REM /t:SlowCheetah			<-- Execute SlowCheetah Transforms in project that point to folder in solution
REM /t:Compile				<-- Call the Compile Function
REM /t:Build				<-- Needs Default
REM /p:Flavor=%CONFIGURATION%					<-- For Compiler
REM /p:TargetComputerName=%TargetComputerName%	<-- \\$(TargetComputerName)\SgnlApps\$(MSBuildProjectName)
REM /p:ComputerName			<-- Default is current machine
REM /p:FireDaemonFileName	<-- Default is FireDaemon.xml

REM Changes Untested:
REM /p:SlowCheetahTargets
REM /p:MSDeployPath			<-- $(ProgramFiles)\IIS\Microsoft Web Deploy V3\msdeploy.exe
REM /p:BuildNumber			<-- $(BUILD_NUMBER) <<!!!!  Doesn't Work!!!!
REM /p:BuildNumber			<-- Default = ??
REM /p:BackupFullPath		<-- \\SG-CA01-NAS-001\Department\Shared_IS\Applications\$(MSBuildProjectName)
REM /p:FullTargetPath       <-- \\$(TargetComputerName)\SgnlApps\$(MSBuildProjectName)
REM /p:FullOutputPath		<-- $(MSBuildProjectDirectory)\bin\$(FLAVOR)
REM /p:PackageFilename		<-- $(MSBuildProjectName)_$[System.DateTime]::Now.ToString("yyyy.MM.dd")).zip
REM ****************************************************

REM Run CMD script on Remote Machine
REM Still Needed..
REM **************
REM @ECHO ON
REM Call CMD remotely
REM %ProjectName%.firedaemon.deploy.cmd

pushd "%~dp0"
REM pause
