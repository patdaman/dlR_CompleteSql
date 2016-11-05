CREATE FUNCTION fnIsVowel( @c char(1) )
RETURNS bit
AS
BEGIN
	IF (@c = 'A') OR (@c = 'E') OR (@c = 'I') OR (@c = 'O') OR (@c = 'U') OR (@c = 'Y') 
	BEGIN
		RETURN 1
	END
	--'ELSE' would worry SQL Server, it wants RETURN last in a scalar function
	RETURN 0
END