-- =============================================
-- Author:		dtorres
-- Create date: 8/13/2015
-- Description:	Classified patient 203 status as New or Relapsed
-- =============================================
CREATE FUNCTION [dbo].[udf_Classify_203_PatientStatus]
(
	@Icd9Codes nvarchar(max),
	@RepeatCount int
)
RETURNS nvarchar(8)
AS
BEGIN
	DECLARE @class nvarchar(80) = 'Invalid' 

	IF @Icd9Codes like '%203.00%' AND @RepeatCount < 2 
		SET @class = 'New'
	ELSE IF @Icd9Codes like '%203.02%' AND @RepeatCount < 3
		SET @class = 'Relapsed'

	RETURN @class

END