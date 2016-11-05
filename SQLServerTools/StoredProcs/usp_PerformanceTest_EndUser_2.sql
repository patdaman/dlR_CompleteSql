-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-03
-- Description:	End User Profile
-- =============================================
CREATE PROCEDURE [dbo].[usp_PerformanceTest_EndUser]
	@AgentJobs		VARCHAR(MAX)
	, @MachineNames	VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @StartTime		DATETIME2(7)
	DECLARE @EndTime		DATETIME2(7)
	DECLARE @TotTime		TIME
	DECLARE @JobName		VARCHAR(128)
	DECLARE @job1_status	BIT
	DECLARE @job2_status	BIT
	DECLARE @LogName		VARCHAR(128)
	DECLARE @MachineName	VARCHAR(128)
	DECLARE @output			INT
	DECLARE @range			VARCHAR(MAX)

	SET @MachineName = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(128))
	SET @MachineNames = COALESCE(@MachineNames, '')
	SET @LogName = @MachineName + '_' + CONVERT(VARCHAR(20), GETDATE(), 120)
	SET @StartTime = GETDATE()
	SET @job1_status = 1
	SET @job2_status = 1
	SET @AgentJobs = COALESCE(@AgentJobs, '')

	IF (@AgentJobs = '')
		GOTO NoAgents

	EXEC [dbo].[usp_PerfMonJobs] @DeleteExisting = 0

	SET @StartTime = GETDATE()

	DECLARE Jobs CURSOR LOCAL FOR
	SELECT Item
	FROM [dbo].udf_DelimitedSplit(@AgentJobs,',')

	OPEN Jobs

	FETCH NEXT FROM Jobs INTO @JobName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @JobName = LTRIM(RTRIM(@JobName))
		EXEC msdb.dbo.sp_start_job @JobName
		FETCH NEXT FROM Jobs INTO @JobName
	END

	CLOSE Jobs
	DEALLOCATE Jobs
	WAITFOR DELAY '00:00:15' 

	WHILE (@job2_status = 1)
	BEGIN
		WAITFOR DELAY '00:00:03'
		SET @job2_status = 0
		DECLARE Jobs CURSOR LOCAL FOR
		SELECT Item
		FROM [dbo].udf_DelimitedSplit(@AgentJobs,',')

		OPEN Jobs

		FETCH NEXT FROM Jobs INTO @JobName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @JobName = LTRIM(RTRIM(@JobName))
			EXEC @job1_status = [dbo].[usp_JobIsRunning] @JobName = @JobName
			IF @job1_status = 1
				SET @job2_status = 1
			FETCH NEXT FROM Jobs INTO @JobName
		END

		CLOSE Jobs
		DEALLOCATE Jobs
	END

	SET @EndTime = GETDATE()
	SET @TotTime = CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, @StartTime, @EndTime), 0))

	PRINT 'Start Time: ' + CAST(@StartTime AS VARCHAR(20))
	PRINT 'End Time: ' + CAST(@EndTime AS VARCHAR(20))
	PRINT 'Total Time: ' + CAST(CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, @StartTime, @EndTime), 0)) AS VARCHAR(20))

	WAITFOR DELAY '00:00:03'
	
	DECLARE Jobs CURSOR LOCAL FOR
	SELECT Item
	FROM [dbo].udf_DelimitedSplit(@AgentJobs,',')

	OPEN Jobs

	FETCH NEXT FROM Jobs INTO @JobName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @JobName = LTRIM(RTRIM(@JobName))
		SET @range = CASE WHEN @JobName LIKE 'PerformanceTest-GetBillingSuiteCase%' THEN 'All Dates'
							WHEN @JobName LIKE 'PerformanceTest-UpdateALL' THEN 'Update All'
							WHEN @JobName LIKE 'PerformanceTest-Get90DaysCases' THEN '90 Days'
							WHEN @JobName LIKE 'PerformanceTest-Get30DaysCases' THEN '30 Days'
							ELSE @JobName
						END
		SET @JobName = CASE WHEN @JobName LIKE 'PerformanceTest-GetBillingSuiteCase%' THEN 'usp_GetBillingSuiteCase'
							WHEN @JobName LIKE 'PerformanceTest-UpdateALL' THEN 'usp_UpdateLisWarehouse'
							WHEN @JobName LIKE 'PerformanceTest-Get90DaysCases' THEN 'usp_GetBillingSuiteCase'
							WHEN @JobName LIKE 'PerformanceTest-Get30DaysCases' THEN 'usp_GetBillingSuiteCase'
							ELSE @JobName
						END

		INSERT INTO [dbo].[BillingSuiteEndUserPerfTest]
			   ([SignalBuildName]
			   ,[BillingSuiteVersion]
			   ,[DateTimeStarted]
			   ,[DateTimeEnded]
			   ,[MachineName]
			   ,[AvgCpuTime]
			   ,[AvgPhysicalReads]
			   ,[AvgLogicalReads]
			   ,[AvgLogicalWrites]
			   ,[TotTestQueryTime]
			   ,[MinElapsedTime]
			   ,[AvgElapsedTime]
			   ,[MaxElapsedTime]
			   ,[AvgDuration]
			   ,[AgentJob]
			   ,[Range]
			   ,[ExecutionCount]
			   ,[LastExecutionTime]
			   ,[UserName])
		 SELECT
			   WH.SignalBuildName
			   , WH.SignalBuildVersion
			   , @StartTime
			   , @EndTime
			   , @MachineName
			   , (CONVERT(float,d.total_worker_time) / d.execution_count)/1000000
			   , (total_physical_reads / execution_count)
			   , (total_logical_reads / execution_count)
			   , (total_logical_writes / execution_count)
			   , @TotTime
			   , (CONVERT(float,d.min_elapsed_time) / 1000000)
			   , (CONVERT(float,d.total_elapsed_time) / d.execution_count) / 1000000
			   , (CONVERT(float,d.max_elapsed_time) / 1000000)
			   , (CONVERT(float,d.total_elapsed_time) / d.execution_count) / 1000000
			   , OBJECT_NAME(object_id, database_id) 'StoredProcedure'
			   , @range 
				, execution_count
				, last_execution_time
				, SUSER_NAME()
		FROM sys.dm_exec_procedure_stats AS d
				LEFT OUTER JOIN (
				SELECT TOP 1 *
				FROM dbo.WarehouseSettings
				ORDER BY InstallUtcDate DESC
				) WH ON 1=1
		WHERE OBJECT_NAME(object_id, database_id) = @JobName
		FETCH NEXT FROM Jobs INTO @JobName
	END

	CLOSE Jobs
	DEALLOCATE Jobs

	GOTO NoAgents
	NoAgents:
	SELECT WH.SignalBuildName
		, TEST.*
	FROM [SGNL_WAREHOUSE].[dbo].[BillingSuiteEndUserPerfTest] TEST
		LEFT OUTER JOIN (
			SELECT TOP 1 *
			FROM dbo.WarehouseSettings
			ORDER BY InstallUtcDate DESC
			) WH ON 1=1
	--WHERE TEST.MachineName LIKE '%' + @MachineName + '%'
	WHERE TEST.MachineName IN (SELECT Item
								FROM [dbo].udf_DelimitedSplit(@MachineNames,','))
		OR @MachineNames = ''
	ORDER BY DateTimeEnded DESC

END