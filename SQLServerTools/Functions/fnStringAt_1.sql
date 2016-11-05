CREATE FUNCTION fnStringAt( @Start int, @StringToSearch varchar(50), @TargetStrings 
varchar(2000) )
RETURNS bit
AS
BEGIN
	DECLARE @SingleTarget varchar(50)
	DECLARE @CurrentStart int
	DECLARE @CurrentLength int
	
	--Eliminate special cases
	--Trailing space is needed to check for end of word in some cases, so always append 
	--	comma
	--loop tests should fairly quickly ignore ',,' termination
	SET @TargetStrings = @TargetStrings + ','
	
	SET @CurrentStart = 1
	--Include terminating comma so spaces don't get truncated
	SET @CurrentLength = (CHARINDEX(',',@TargetStrings,@CurrentStart) - @CurrentStart) + 1
	SET @SingleTarget = SUBSTRING(@TargetStrings,@CurrentStart,@CurrentLength)
	WHILE LEN(@SingleTarget) > 1
	BEGIN
		IF SUBSTRING(@StringToSearch,@Start,LEN(@SingleTarget)-1) = LEFT(@SingleTarget,LEN(@SingleTarget)-1)
		BEGIN
			RETURN 1
		END
		SET @CurrentStart = (@CurrentStart + @CurrentLength)
		SET @CurrentLength = (CHARINDEX(',',@TargetStrings,@CurrentStart) - @CurrentStart) + 1
		IF NOT @CurrentLength > 1 --getting trailing comma 
		BEGIN
			BREAK
		END
		SET @SingleTarget = SUBSTRING(@TargetStrings,@CurrentStart,@CurrentLength)
	END
	RETURN 0
END