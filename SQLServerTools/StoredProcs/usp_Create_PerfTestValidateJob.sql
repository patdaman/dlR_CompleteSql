-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-14
-- Description:	Add New PerformanceTest or Validation Job
-- =============================================
CREATE PROCEDURE usp_Create_PerfTestValidateJob 
	@JobName		VARCHAR(128)	= NULL
	, @Description	VARCHAR(8000)	= NULL
	, @Step1Name	VARCHAR(128)	= NULL
	, @Step1Db		VARCHAR(128)	= NULL
	, @Step1		VARCHAR(8000)	= NULL
	, @Step2Name	VARCHAR(128)	= NULL
	, @Step2Db		VARCHAR(128)	= NULL
	, @Step2		VARCHAR(8000)	= NULL
	, @Step3Name	VARCHAR(128)	= NULL
	, @Step3Db		VARCHAR(128)	= NULL
	, @Step3		VARCHAR(8000)	= NULL
	, @Email		VARCHAR(128)	= NULL
	, @EmailError		bit		= 0
	, @isPerformance	bit		= 0
	, @DeleteExisting	bit		= 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @jobId		binary(16)
	DECLARE @ReturnCode INT

	SET @Description = COALESCE(@Description, N'No description available.')

	SET @Step1Db	= COALESCE(@Step1Db, N'master')
	SET @Step2Db	= COALESCE(@Step2Db, N'master')
	SET @Step3Db	= COALESCE(@Step3Db, N'master')

	SET @Step1Name	= COALESCE(@Step1Name, N'Step1')
	SET @Step2Name	= COALESCE(@Step2Name, N'Step2')
	SET @Step3Name	= COALESCE(@Step3Name, N'Step3')

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE name = @JobName

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END
	
	IF @jobId IS NULL
	BEGIN

		BEGIN TRANSACTION
		SELECT @ReturnCode = 0

		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1

		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@JobName, 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description= @Description, 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1

		IF (@Step1 IS NOT NULL)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name = @Step1Name, 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=3, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command=@Step1, 
					@database_name= @Step1Db, 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
				GOTO QuitWithRollback1
		END

		IF (@Step1 IS NOT NULL AND @Step2 IS NOT NULL)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name= @Step2Name, 
					@step_id=2, 
					@cmdexec_success_code=0, 
					@on_success_action=3, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command= @Step2, 
					@database_name= @Step2Db, 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
				GOTO QuitWithRollback1
		END

		IF (@Step1 IS NOT NULL AND @Step2 IS NOT NULL AND @Step3 IS NOT NULL)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name= @Step3Name, 
					@step_id=3, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command= @Step3, 
					@database_name= @Step3Db, 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
				GOTO QuitWithRollback1
		END

		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1
		COMMIT TRANSACTION

		GOTO EndSave1
	
		QuitWithRollback1:
			IF (@@TRANCOUNT > 0) 
				ROLLBACK TRANSACTION
		EndSave1:
	END
END