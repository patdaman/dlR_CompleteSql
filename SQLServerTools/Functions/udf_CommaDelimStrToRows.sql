CREATE FUNCTION [dbo].[udf_CommaDelimStrToRows] (@CommadelimitedString   varchar(1000))
RETURNS   @Result TABLE (Id int, Val   VARCHAR(100))
AS
BEGIN
        DECLARE @IntLocation INT, @cnt int
		SET @cnt =1
        WHILE (CHARINDEX(',',    @CommadelimitedString, 0) > 0)
        BEGIN
              SET @IntLocation =   CHARINDEX(',',    @CommadelimitedString, 0)      
              INSERT INTO   @Result (id, Val)
              --LTRIM and RTRIM to ensure blank spaces are   removed
              SELECT @cnt, RTRIM(LTRIM(SUBSTRING(@CommadelimitedString,   0, @IntLocation)))   
              SET @CommadelimitedString = STUFF(@CommadelimitedString,   1, @IntLocation,   '') 
			  SET @cnt = @cnt+1
        END
        INSERT INTO   @Result (id, Val)
        SELECT @cnt, RTRIM(LTRIM(@CommadelimitedString))--LTRIM and RTRIM to ensure blank spaces are removed
        RETURN 
END