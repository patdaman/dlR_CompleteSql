-- =============================================
-- Author:		dtorres
-- Create date: 8/13/2015
-- Description:	classify the BillingClassification column
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_BillingClass]
(	
	@CaseNumber nvarchar(max),		
	@BillType nvarchar(max),	
	@ClientName nvarchar(max),
	@Deficiencies nvarchar(max),
	@Icd9Codes nvarchar(max),	
	@FacilityName nvarchar(max),
	@PatientStatus nvarchar(max),		
	@PatientLastName nvarchar(max),			
	@Qns nvarchar(max),	
	@QnsReason nvarchar(max),	
	@RepeatCount int,
	@SpecimenType nvarchar(max)
)
RETURNS varchar(80)
AS
BEGIN
	
	DECLARE @class nvarchar(80) = 'Unclassified' -- Used to catch errors, nothing should be unclassified.


	DECLARE @BillableStatus nvarchar(max) =  dbo.udf_Classify_BillableStatus( 
		@CaseNumber, 
		@PatientLastName, 
		@FacilityName,
		@Deficiencies,
		@ClientName,
		@BillType )


	DECLARE @ProgramGroup nvarchar(max) = dbo.udf_Classify_ProgramGroup(
		@BillableStatus,
		@ClientName	)
	
	IF @BillableStatus <> 'Billable'
		SET @class = @BillableStatus
	ELSE 
		BEGIN
			IF @ProgramGroup = 'UAMS'
				SET @class = dbo.udf_Classify_UamsBilling( 
					@ProgramGroup,
					@CaseNumber, 
					@Qns, 
					@QnsReason, 
					@Icd9Codes, 
					@BillType, 
					@PatientStatus, 
					@SpecimenType, 
					@RepeatCount)

			ELSE IF @ProgramGroup = 'Pharma'
				SET @class = dbo.udf_Classify_PharmaBilling(
					@ProgramGroup, 
					@Qns,
					@BillType)

			ELSE IF @ProgramGroup = 'Clinical'
				SET @class = dbo.udf_Classify_ClinicalBilling(
					@ProgramGroup, 
					@CaseNumber,
					@ClientName,
					@Qns,
					@Icd9Codes,
					@BillType,
					@RepeatCount)			
		END
	

	RETURN @class
	
END