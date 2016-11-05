
-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-12-09
-- Description:	Checks if Agent Job is currently running
-- =============================================
CREATE PROCEDURE [dbo].[usp_JobIsRunning] 
(
	@JobName VARCHAR(128) = NULL
	, @isRunning	BIT	= 0 OUTPUT
)

AS
BEGIN
	DECLARE @RunningJobs TABLE (  
		Job_ID UNIQUEIDENTIFIER,  
		Last_Run_Date INT,  
		Last_Run_Time INT,  
		Next_Run_Date INT,  
		Next_Run_Time INT,  
		Next_Run_Schedule_ID INT,  
		Requested_To_Run INT,  
		Request_Source INT,  
		Request_Source_ID VARCHAR(100),  
		Running INT,  
		Current_Step INT,  
		Current_Retry_Attempt INT,  
		State INT )    
     
	INSERT INTO @RunningJobs EXEC master.dbo.xp_sqlagent_enum_jobs 1,garbage 

	IF EXISTS(SELECT 1 FROM @RunningJobs JSR 
		JOIN     msdb.dbo.sysjobs 
		ON       JSR.Job_ID=sysjobs.job_id 
		WHERE    Running=1 -- i.e. still running
			AND name LIKE '%' + @JobName + '%'
		)
		SET @isRunning = 1
	ELSE
		SET @isRunning = 0

	RETURN (@isRunning)
END