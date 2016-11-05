CREATE FUNCTION fnDoubleMetaphoneScalar( @MetaphoneType int, @Word varchar(50) )
RETURNS char(4)
AS
BEGIN
		RETURN (SELECT CASE @MetaphoneType WHEN 1 THEN Metaphone1 
WHEN 2 THEN Metaphone2 END FROM fnDoubleMetaphoneTable( @Word ))
END