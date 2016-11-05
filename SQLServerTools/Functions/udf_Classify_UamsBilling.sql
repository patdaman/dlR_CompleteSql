-- =============================================
-- Author:		dtorres
-- Create date: 8/13/2015
-- Description:	classify UAMS billing categories
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_UamsBilling]
(
	@ProgramGroup nvarchar(max),	
	@CaseNumber nvarchar(max),	
	@Qns nvarchar(max),	
	@QnsReason nvarchar(max),
	@Icd9Codes nvarchar(max),
	@BillType nvarchar(max),
	@PatientStatus nvarchar(max),
	@SpecimenType nvarchar(max),
	@RepeatCount int
)
RETURNS varchar(80)
AS
BEGIN

	DECLARE @class nvarchar(80) = 'UAMS Research' -- Used to catch errors, nothing should be unclassified.

	DECLARE @Patient_203_Status nvarchar(16) = dbo.udf_Classify_203_PatientStatus(@Icd9Codes,@RepeatCount)

	IF @ProgramGroup <> 'UAMS' 
		SET @class = 'NA'	
	ELSE 
	BEGIN 
		IF @CaseNumber like 'SO%'
			SET @class = 'UAMS Sort Only'
		
		ELSE IF @BillType like 'No Charge'
			SET @class = 'UAMS No Charge'
		
		ELSE IF @QNS = 'True'
			BEGIN
				IF (@QnsReason not like 'Sample Not Provided')
					and not ( @CaseNumber like 'BI%' and @QnsReason like 'RNA Integrity' )
					SET @class = 'UAMS QNS Billable'				
			END

		ELSE IF @Qns = 'False'
			BEGIN
				IF @CaseNumber like 'BI%' 
					SET @class = 'UAMS Biopsy'
				
				ELSE IF @SpecimenType like '%Bone Marrow%' 
					BEGIN
						IF @BillType like 'Medicare' 
						AND @PatientStatus like 'New Patient/EP Initial Therapy'
						AND @Patient_203_Status like 'New'
							SET @class = 'UAMS Medicare New'

						ELSE IF @BillType like 'Medicare' 
						AND @PatientStatus like 'Relapse/Suspected Relapse'
						AND @Patient_203_Status like 'Relapse'
							SET @class = 'UAMS Medicare Relapse'

						ELSE IF @BillType like '%Private Insurance%'
						AND @Patient_203_Status like 'New' 
							SET @class = 'UAMS Xifin New'

						ELSE IF @BillType like '%Private Insurance%'
						AND @Patient_203_Status like 'Relapse' 
							SET @class = 'UAMS Xifin Relapse'							
					END 
			END
	END

	-- Return the result of the function
	RETURN @class

END