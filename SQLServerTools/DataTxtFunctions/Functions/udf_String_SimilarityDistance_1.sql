CREATE FUNCTION [dbo].[udf_String_SimilarityDistance]
(
  @String1 nvarchar(3999),
  @String2 nvarchar(3999))
RETURNS int
AS
BEGIN
  DECLARE @String1_len int, @String2_len int
  DECLARE @i int, @j int, @String1_char nchar, @c int, @c_temp int
  DECLARE @cv0 varbinary(8000), @cv1 varbinary(8000)
  SELECT
    @String1_len = LEN(@String1),
    @String2_len = LEN(@String2),
    @cv1 = 0x0000,
    @j = 1, @i = 1, @c = 0
 
  WHILE @j <= @String2_len
    SELECT @cv1 = @cv1 + CAST(@j AS binary(2)), @j = @j + 1
  WHILE @i <= @String1_len
 
  BEGIN
    SELECT
      @String1_char = SUBSTRING(@String1, @i, 1),
      @c = @i,
      @cv0 = CAST(@i AS binary(2)),
      @j = 1
 
    WHILE @j <= @String2_len
    BEGIN
      SET @c = @c + 1
      SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j-1, 2) AS int) +
        CASE WHEN @String1_char = SUBSTRING(@String2, @j, 1) THEN 0 ELSE 1 END
      IF @c > @c_temp SET @c = @c_temp
      SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j+1, 2) AS int)+1
      IF @c > @c_temp SET @c = @c_temp
      SELECT @cv0 = @cv0 + CAST(@c AS binary(2)), @j = @j + 1
    END
    SELECT
      @cv1 = @cv0,
      @i = @i + 1
  END
 
  RETURN @c
END