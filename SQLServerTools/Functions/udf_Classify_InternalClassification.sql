-- =============================================
-- Author:		dtorres
-- Create date: 10/19/2015
-- Description:	Calculates Internal Classifiaction column
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_InternalClassification]
(	
	@ProgramGroup nvarchar(max), 
	@ClientName nvarchar(max),
	@FacilityName nvarchar(max),
	@CaseNumber nvarchar(max)
)
RETURNS varchar(80)
AS
BEGIN
		
	DECLARE @class nvarchar(80) = 'NotInternal' -- Used to catch errors, nothing should be unclassified.
	
	IF @ProgramGroup = 'Internal'
	BEGIN 
		IF @CaseNumber like 'QC%' 
			OR ( @ClientName = 'Lot to Lots' )
			OR ( @ClientName = 'Proficiency test' )
			SET @class = 'QualityAssurance'
		ELSE IF @ClientName = 'SG - Internal Research'		
			SET @class = 'InternalResearch'
		ELSE 
			SET @class = 'InternalOther'
	END
			
	-- Return the result of the function
	RETURN @class

END