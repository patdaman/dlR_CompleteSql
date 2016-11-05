-- =============================================
-- Author:		dtorres
-- Create date: 8/13/2015
-- Description:	classify pharma billing categories
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_PharmaBilling]
(
	@ProgramGroup nvarchar(max),	
	@Qns nvarchar(max),	
	@BillType nvarchar(max)
)
RETURNS varchar(80)
AS
BEGIN

	DECLARE @class nvarchar(80) = 'Unclassified' -- Used to catch errors, nothing should be unclassified.

	IF @ProgramGroup <> 'Pharma' 
		SET @class = 'NA'
	ELSE 
	BEGIN
		IF @BillType like '%No Charge%'
			SET @class = 'Pharma No Charge'
		ELSE IF @Qns like 'True'
			SET @class = 'Pharma QNS Billing'
		ELSE SET @class = 'Pharma Non-QNS Billing'
	END

	-- Return the result of the function
	RETURN @class

END