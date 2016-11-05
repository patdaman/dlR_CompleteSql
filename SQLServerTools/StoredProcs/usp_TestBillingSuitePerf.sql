-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-03
-- Description:	End User Profile
-- =============================================
CREATE PROCEDURE [dbo].[usp_TestBillingSuitePerf]
	@TruncateData	BIT				= 0
	, @AgentJobs	VARCHAR(MAX)	= NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @StartTime		DATETIME2(7)
	DECLARE @EndTime		DATETIME2(7)
	DECLARE @TotTime		TIME
	DECLARE @JobName		VARCHAR(128)
	DECLARE @job1_status	BIT
	DECLARE @job2_status	BIT
	DECLARE @ProfileStatus	BIT
	DECLARE @LogName		VARCHAR(128)
	DECLARE @MachineName	VARCHAR(128)
	DECLARE @output			INT

	SET @MachineName = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(20))
	SET @LogName = @MachineName + '_' + CONVERT(VARCHAR(20), GETDATE(), 120)
	SET @StartTime = GETDATE()
	SET @job1_status = 0
	SET @job2_status = 0
	SET @ProfileStatus = 1
	SET @AgentJobs = COALESCE(@AgentJobs, '')

	IF @AgentJobs = ''
		GOTO NoAgents

	IF (OBJECT_ID('CounterData', 'U') IS NOT NULL
		AND @TruncateData = 1)
		TRUNCATE TABLE [dbo].[CounterData]
	IF (OBJECT_ID('CounterDetails', 'U') IS NOT NULL
		AND @TruncateData = 1)
		TRUNCATE TABLE [dbo].[CounterDetails]
	IF (OBJECT_ID('DisplayToID', 'U') IS NOT NULL
		AND @TruncateData = 1)
		TRUNCATE TABLE [dbo].[DisplayToID]

	EXEC [dbo].[usp_PerfMonJobs] @DeleteExisting = 0
	EXEC msdb.dbo.sp_start_job N'PerformanceTest-Enable_xp_cmdshell'
	WAITFOR DELAY '00:00:05'

	IF OBJECT_ID('tempdb..ResultSet') IS NOT NULL
		DROP TABLE #ResultSet
	CREATE TABLE #ResultSet (Directory varchar(200))
	INSERT INTO #ResultSet
	EXEC master.dbo.xp_subdirs 'c:\'
	IF NOT EXISTS(Select 1 FROM #ResultSet where Directory = 'temp')
		EXEC master.sys.xp_create_subdir 'C:\temp\'

	--EXEC @output = XP_CMDSHELL 'DIR "C:\temp\SQLPerfMon.txt" /B', NO_OUTPUT
	EXEC @output = XP_CMDSHELL 'DIR "D:\PerfMonTemplate\DevCounters.txt" /B', NO_OUTPUT
	IF @output = 1
	BEGIN
		PRINT 'File Does not exist'
		RETURN
	END
	ELSE BEGIN
		PRINT 'File exists'
	END

	EXEC @ProfileStatus = [dbo].[usp_JobIsRunning] @JobName = N'PerformanceTest-PerfMon'
	
	WHILE @ProfileStatus = 1
	BEGIN
		WAITFOR DELAY '00:00:05'
		EXEC @ProfileStatus = [dbo].[usp_JobIsRunning] @JobName = N'PerformanceTest-PerfMon'
		IF @StartTime < DATEADD(MI, -1, GETDATE())
			EXEC msdb.dbo.sp_stop_job N'PerformanceTest-PerfMon'
	END

	EXEC msdb.dbo.sp_start_job N'PerformanceTest-PerfMon'
	WAITFOR DELAY '00:00:05'

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

	-- WAITFOR DELAY '00:00:01'

	WHILE (@job2_status = 1)
	BEGIN
		SET @job2_status = 0
		--WAITFOR DELAY '00:00:01'
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
PRINT 'JobName: ' + @JobName
PRINT 'job1_status: ' + CONVERT(VARCHAR(1),@job1_status)
PRINT 'job2_status: ' + CONVERT(VARCHAR(1),@job2_status)
PRINT (CHAR(13) + CHAR(10))
		END

		CLOSE Jobs
		DEALLOCATE Jobs
	END

	SET @EndTime = GETDATE()
	SET @TotTime = CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, @StartTime, @EndTime), 0))

	PRINT 'Start Time: ' + CAST(@StartTime AS VARCHAR(20))
	PRINT 'End Time: ' + CAST(@EndTime AS VARCHAR(20))
	PRINT 'Total Time: ' + CAST(CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, @StartTime, @EndTime), 0)) AS VARCHAR(20))

	INSERT INTO SGNL_WAREHOUSE.dbo.BillingSuitePerfTest
		(TestGUID, BillingSuiteVersion, ConcurrentRuns, DateTimeStarted, DateTimeEnded, MachineName
			, CounterName, MinCpuValue, MaxCpuValue, AvgCpuValue, TotTestQueryTime
			, MinMemory, MaxMemory, AvgMemory, AvgWaitTime, Deadlocks, Timeouts, TempTables, AgentJobs)
	SELECT TOP 1
		d.GUID
		, MAX(WH.SignalBuildVersion)
		, 1
		, @StartTime
		, @EndTime
		, @MachineName
		, d.DisplayString
		, MIN(cpu.CounterValue) AS minCpu
		, MAX(cpu.CounterValue) AS maxCpu
		, AVG(cpu.CounterValue) AS avgCpu
		, @TotTime
		, MIN(MEM.CounterValue) AS minMem
		, MAX(MEM.CounterValue) AS maxMem
		, AVG(MEM.CounterValue) AS avgMem
		, AVG(Locks.CounterValue) AS AvgWaitTime
		, MAX(Temp.CounterValue) AS ActiveTempTables
		, MAX(DeadLocks.CounterValue) AS Deadlocks
		, MAX(TimeOuts.CounterValue) AS Timeouts
		, @AgentJobs AS AgentJobs
	FROM dbo.CounterDetails cdt
		INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
		INNER JOIN dbo.DisplayToID d ON d.GUID = cd.GUID
		LEFT OUTER JOIN (
			SELECT cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE
				cdt.ObjectName = 'SQLServer:General Statistics'
				AND cdt.CounterName = 'Active Temp Tables'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121) 
		) Temp ON cdt.CounterID = Temp.CounterID
		LEFT OUTER JOIN (
			SELECT 
				cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE cdt.ObjectName = 'Processor'
				AND cdt.CounterName = '% Processor Time'
				AND cdt.InstanceName = '_Total'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121)
		) CPU ON cdt.CounterID = CPU.CounterID
		LEFT OUTER JOIN (
			SELECT 
				cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE cdt.ObjectName = 'Memory'
				AND cdt.CounterName = '% Committed Bytes In Use'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121)
		) MEM ON cdt.CounterID = MEM.CounterID
		LEFT OUTER JOIN (
			SELECT 
				cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE cdt.ObjectName = 'SQLServer:Locks'
				AND cdt.InstanceName = '_Total'
				AND cdt.CounterName LIKE  '%Wait Time%'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121)
		) Locks ON cdt.CounterID = Locks.CounterID
		LEFT OUTER JOIN (
			SELECT 
				cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE cdt.ObjectName = 'SQLServer:Locks'
				AND cdt.InstanceName = '_Total'
				AND cdt.CounterName = 'Number of Deadlocks/sec'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121)
		) DeadLocks ON cdt.CounterID = Locks.CounterID
		LEFT OUTER JOIN (
			SELECT 
				cdt.CounterID
				, cd.CounterValue
			FROM dbo.CounterDetails cdt
				INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
			WHERE cdt.ObjectName = 'SQLServer:Locks'
				AND cdt.InstanceName = '_Total'
				AND cdt.CounterName LIKE '%Timeouts%'
				AND cd.CounterDateTime < CONVERT(VARCHAR(24),@EndTime,121)
		) TimeOuts ON cdt.CounterID = TimeOuts.CounterID
		LEFT OUTER JOIN (
			SELECT TOP 1 *
			FROM dbo.WarehouseSettings
			ORDER BY InstallUtcDate DESC
			) WH ON 1=1
	WHERE cdt.MachineName LIKE '%' + @MachineName + '%'
	GROUP BY cdt.MachineName, d.DisplayString, d.LogStopTime, d.GUID
	ORDER BY d.LogStopTime DESC

	GOTO NoAgents
	NoAgents:
	SELECT WH.SignalBuildName
		, TEST.*
	FROM [SGNL_WAREHOUSE].[dbo].[BillingSuitePerfTest] TEST
		LEFT OUTER JOIN (
			SELECT TOP 1 *
			FROM dbo.WarehouseSettings
			ORDER BY InstallUtcDate DESC
			) WH ON 1=1
	WHERE TEST.MachineName LIKE '%' + @MachineName + '%'
	ORDER BY DateTimeEnded DESC

	IF OBJECT_ID('tempdb..ResultSet') IS NOT NULL
		DROP TABLE #ResultSet
END