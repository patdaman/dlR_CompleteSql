@ECHO OFF
SET ProjectName=%1
SET "ProjectName=Xifin_LIS"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\Xifin_LIS"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%

REM pause

@ECHO OFF
SET ProjectName=%1
SET "ProjectName=SGNL_LIS"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_LIS"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%

REM pause

@ECHO OFF
SET ProjectName=%1
SET "ProjectName=SGNL_INTERNAL"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_INTERNAL"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%

REM pause

@ECHO OFF
SET ProjectName=%1
SET "ProjectName=SGNL_FINANCE"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_FINANCE"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%

REM pause

@ECHO OFF
SET ProjectName=%1
SET "ProjectName=SGNL_WAREHOUSE"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_WAREHOUSE"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%

REM pause

@ECHO OFF
SET ProjectName=%1
SET "ProjectName=SGNL_ANALYTICS"
SET ProjectPath=%2
SET "ProjectPath=E:\SignalMasterRepo\sgnlmasterrepo\SQL\SQLSignalInformatics\SGNL_ANALYTICS"
SET Flavor=%3
SET Flavor=SignalCi
SET Build=%4
SET	"Build=Test"
SET BackupPath=%6
SET "BackupPath=\\SG-CA01-DVM-004\SignalCi"

REM ****************************************************** REM
ECHO Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
Call AutoDbDeploy.cmd %ProjectName% %ProjectPath% %Flavor% %Build% %BackupPath%
