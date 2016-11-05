-- =============================================
-- Author:		dtorres
-- Create date: 8/13/2015
-- Description:	classify clinical billing categories
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_ClinicalBilling]
(
	@ProgramGroup nvarchar(max),
	@CaseNumber nvarchar(max),
	@ClientName nvarchar(max),
	@Qns nvarchar(max),
	@Icd9Codes nvarchar(max),
	@BillType nvarchar(max),
	@RepeatCount int
)
RETURNS varchar(80)
AS
BEGIN

	DECLARE @class nvarchar(80) = 'Unclassified' -- Used to catch errors, nothing should be unclassified.

	IF @ProgramGroup <> 'Clinical' 
		SET @class = 'NA'	
	ELSE 
	BEGIN
		IF @Qns = 'True' 
			SET @class = 'Non-UAMS QNS'
		ELSE IF @BillType = '%No Charge%'
			SET @class = 'Non-UAMS No Charge'		
		ELSE IF @ClientName like 'Cleveland Clinic'
			SET @class = 'Cleveland Clinic'
		ELSE IF @ClientName like 'Johns Hopkins Hospital' or @ClientName like '%Kansas City VA Medical Center%'
			SET @class = 'Non-UAMS Quest'
		ELSE 
			BEGIN
				IF @Icd9Codes like '%203.02%' and @RepeatCount < 3
					SET @class = 'Non-UAMS Xifin Relapsed'
				ELSE IF @Icd9Codes like '%203.00%' and @RepeatCount < 2
					SET @class = 'Non-UAMS Xifin New'
				ELSE 
					SET @class = 'Non-UAMS Manual Bill'
			END
	END

	-- Return the result of the function
	RETURN @class

END