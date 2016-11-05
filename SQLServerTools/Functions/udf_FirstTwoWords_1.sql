-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-08-27
-- Description:	Return First Two Words of String, 
--				1 word if only 1 word long, 
--				or blank string if empty.
-- =============================================
CREATE FUNCTION udf_FirstTwoWords 
(
	-- Add the parameters for the function here
	@string varchar(250)
)
RETURNS varchar(250)
AS
BEGIN
	DECLARE @FirstTwoWords varchar(250)

	SELECT @FirstTwoWords = CASE CHARINDEX(' ', @string)
							WHEN 0 
								THEN @string
							ELSE (CASE CHARINDEX(' ', @string, CHARINDEX(' ',@string))
								WHEN 0 
									THEN @string
								ELSE 
									SUBSTRING(@string, 1, CHARINDEX(' ', @string, CHARINDEX(' ',@string)) - 1)
								END
							) END
	RETURN @FirstTwoWords
END