
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-08
-- Description:	Create performance testing jobs
-- =============================================
CREATE PROCEDURE [dbo].[usp_PerfMonJobs] 
	-- Add the parameters for the stored procedure here
	@DeleteExisting		bit				= 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @jobId binary(16)
	DECLARE @ReturnCode INT

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE (name = N'PerformanceTest-PerfMon')

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END
	
	IF @jobId IS NULL
	BEGIN
		/****** Object:  Job [PerformanceTest-PerfMon]    Script Date: 12/11/2015 12:42:57 PM ******/
		BEGIN TRANSACTION
		SELECT @ReturnCode = 0
		/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/11/2015 12:42:58 PM ******/
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1

		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerformanceTest-PerfMon', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1
		/****** Object:  Step [Enable xp_cmdshell]    Script Date: 12/11/2015 12:42:58 PM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Enable xp_cmdshell', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'
		/* ----------------------------------- */
		/* ----- Enable xp_cmdshell ----- */
		/* ----------------------------------- */
		EXEC sp_configure ''show advanced options'', 1;
		GO
		RECONFIGURE;
		GO
		EXEC sp_configure ''xp_cmdshell'',1
		GO
		RECONFIGURE
		GO

		', 
				@database_name=N'master', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1

		/****** Object:  Step [Run PerfMon Sproc]    Script Date: 12/11/2015 12:42:58 PM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run PerfMon Sproc', 
				@step_id=2, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'DECLARE @LogName	VARCHAR(128)
		DECLARE @RunLength	INT
		DECLARE @MachineName	VARCHAR(128)

		SET @MachineName = CAST(SERVERPROPERTY(''MachineName'') AS VARCHAR(50))
		SET @LogName = ''"'' + @MachineName + ''_'' + CONVERT(VARCHAR(50), GETDATE(), 120) + ''"''
		SET @RunLength = 5

		EXEC [dbo].[usp_PerfMon] 
				@ServerName = @MachineName
				, @ODBCName = ''DevDB''
				, @DefinitionFilePath = N''D:\PerfMonTemplate\DevCounters.txt''
				, @DisplayName = @LogName
				, @Minutes = @RunLength', 
				@database_name=N'SGNL_WAREHOUSE', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1
		/****** Object:  Step [Disable xp_cmdshell]    Script Date: 12/11/2015 12:42:58 PM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Disable xp_cmdshell', 
				@step_id=3, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'/* ----------------------------------- */
		/* ----- Disable xp_cmdshell ----- */
		/* ----------------------------------- */
		EXEC sp_configure ''show advanced options'', 1;
		GO
		RECONFIGURE;
		GO
		EXEC sp_configure ''xp_cmdshell'',0
		GO
		RECONFIGURE
		GO', 
				@database_name=N'master', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback1
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

	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE (name = N'PerformanceTest-GetBillingSuiteCase-All')

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END

	IF @jobId IS NULL
	BEGIN
		SELECT @jobId = job_id 
		FROM msdb.dbo.sysjobs
		WHERE (name = N'PerformanceTest-GetBillingSuiteCase-All')

		IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
		BEGIN
			EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
			SET @jobId = NULL
		END

		BEGIN TRANSACTION
		SELECT @ReturnCode = 0
		/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/22/2016 11:42:50 AM ******/
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2

		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerformanceTest-GetBillingSuiteCase-All', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2
		/****** Object:  Step [Recompile]    Script Date: 1/22/2016 11:42:51 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Recompile', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'sp_recompile ''dbo.usp_GetBillingSuiteCase''', 
				@database_name=N'SGNL_WAREHOUSE', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2
		/****** Object:  Step [Get Cases]    Script Date: 1/22/2016 11:42:51 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Cases', 
				@step_id=2, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'DECLARE @cursor INT
		SET @cursor = 0

		WHILE (@cursor < 10)
		BEGIN
			EXEC [dbo].[usp_GetBillingSuiteCase] 		
						@StartDate = N''2011-01-01'',
						@EndDate = N''2015-12-01'',
						@CaseNumber = NULL,
						@DateType = NULL,
						@Order = NULL,
						@Unbilled = NULL,
						@BillingAggregate = NULL
			SET @cursor = @cursor + 1
		END', 
				@database_name=N'SGNL_WAREHOUSE', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback2
		COMMIT TRANSACTION
		GOTO EndSave2
		QuitWithRollback2:
			IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
		EndSave2:
	END

	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE (name = N'PerformanceTest-GetBillingSuiteCase2014-2015')

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END

	IF @jobId IS NULL
	BEGIN
		/****** Object:  Job [PerformanceTest-GetBillingSuiteCase2014-2015]    Script Date: 1/22/2016 11:45:20 AM ******/
		BEGIN TRANSACTION
		SELECT @ReturnCode = 0
		/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/22/2016 11:45:20 AM ******/
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback3
		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerformanceTest-GetBillingSuiteCase2014-2015', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback3
		/****** Object:  Step [Recompile]    Script Date: 1/22/2016 11:45:20 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Recompile', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'sp_recompile ''dbo.usp_GetBillingSuiteCase''', 
				@database_name=N'SGNL_WAREHOUSE', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback3
		/****** Object:  Step [Get Cases]    Script Date: 1/22/2016 11:45:20 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Cases', 
				@step_id=2, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'DECLARE @cursor INT

		SET @cursor = 0

		WHILE (@cursor < 10)
		BEGIN
	EXEC [dbo].[usp_GetBillingSuiteCase] 		
						@StartDate = N''2014-01-01'',
						@EndDate = N''2015-12-01'',
						@CaseNumber = NULL,
						@DateType = NULL,
						@Order = NULL,
						@Unbilled = NULL,
						@BillingAggregate = NULL
						SET @cursor = @cursor + 1
		END', 
				@database_name=N'SGNL_WAREHOUSE', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback3
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback3
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback3
		COMMIT TRANSACTION
		GOTO EndSave3
		QuitWithRollback3:
			IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
		EndSave3:
	END

	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE (name = N'PerformanceTest-UpdateALL')

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END

	IF @jobId IS NULL
	BEGIN
		/****** Object:  Job [PerformanceTest-UpdateALL]    Script Date: 1/22/2016 11:47:15 AM ******/
		BEGIN TRANSACTION
		SELECT @ReturnCode = 0
		/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/22/2016 11:47:15 AM ******/
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback4
		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerformanceTest-UpdateALL', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback4
		/****** Object:  Step [recompile]    Script Date: 1/22/2016 11:47:15 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'recompile', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'sp_recompile ''dbo.usp_UpdateLisWarehouse''', 
				@database_name=N'SGNL_LIS', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback4
		/****** Object:  Step [Run Update]    Script Date: 1/22/2016 11:47:15 AM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Update', 
				@step_id=2, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'DECLARE @cursor INT

		SET @cursor = 0

		WHILE (@cursor < 10)
		BEGIN

			EXEC dbo.usp_UpdateLisWarehouse ''ALL''
			SET @cursor = @cursor + 1
		END', 
				@database_name=N'SGNL_LIS', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback4
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback4
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback4
		COMMIT TRANSACTION
		GOTO EndSave4
		QuitWithRollback4:
			IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
		EndSave4:
	END

	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	SELECT @jobId = job_id 
	FROM msdb.dbo.sysjobs
	WHERE (name = N'PerformanceTest-Enable_xp_cmdshell')

	IF (@jobId IS NOT NULL AND @DeleteExisting = 1)
	BEGIN
		EXEC msdb.dbo.sp_delete_job @job_id=@jobId, @delete_unused_schedule=1
		SET @jobId = NULL
	END

	IF @jobId IS NULL
	BEGIN
		/****** Object:  Job [PerformanceTest-Enable_xp_cmdshell]    Script Date: 12/11/2015 5:25:54 PM ******/
		BEGIN TRANSACTION
		SELECT @ReturnCode = 0

		/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/11/2015 5:25:54 PM ******/
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
				GOTO QuitWithRollback5
		END

		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerformanceTest-Enable_xp_cmdshell', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback5
		/****** Object:  Step [Enable xp_cmdshell]    Script Date: 12/11/2015 5:25:55 PM ******/
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Enable xp_cmdshell', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'
		/* ----------------------------------- */
		/* ----- Enable xp_cmdshell ----- */
		/* ----------------------------------- */
		EXEC sp_configure ''show advanced options'', 1;
		GO
		RECONFIGURE;
		GO
		EXEC sp_configure ''xp_cmdshell'',1
		GO
		RECONFIGURE
		GO
		', 
				@database_name=N'master', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback5
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback5
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback5
		COMMIT TRANSACTION

		GOTO EndSave5
		QuitWithRollback5:
			IF (@@TRANCOUNT > 0) 
				ROLLBACK TRANSACTION
		EndSave5:
	END
END