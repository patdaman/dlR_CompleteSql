SELECT DISTINCT
	C.Name AS ClientName
	, C.ClientCode AS ClientCode
	, C.Fax AS ClientFax
	, MAX(F.FacilityName) AS FacilityName
	, LTRIM(RTRIM(D.LastName)) + ', ' + LTRIM(RTRIM(D.FirstName)) AS DoctorName
	--, dbo.GROUP_CONCAT_D(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(D.EmailAddress,CHAR(13),''), CHAR(10),''), CHAR(9),''))),'; ') AS DoctorEmail
	, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(D.EmailAddress,CHAR(13),''), CHAR(10),''), CHAR(9),''))) AS DoctorEmail
FROM SGNL_LIS.dbo.Client AS C
	LEFT OUTER JOIN (
		SELECT Ac.ClientId, Ac.OrderingPhysician, C.ClientCode
		FROM SGNL_LIS.dbo.Accession Ac
			INNER JOIN SGNL_LIS.dbo.Client C ON Ac.ClientId = C.id
		) A ON C.ClientCode = A.ClientCode
	LEFT OUTER JOIN SGNL_LIS.dbo.Facility AS F ON C.FacilityId = F.FacilityId
	LEFT OUTER JOIN SGNL_LIS.dbo.Doctor AS D ON A.OrderingPhysician = D.DoctorId
WHERE (
	COALESCE(C.Fax,'') <> ''
		OR
	COALESCE(D.EmailAddress,'') <> ''
)
GROUP BY C.ClientCode, C.Name, C.Fax, D.LastName, D.FirstName, D.EmailAddress
ORDER BY C.Name
GO

-- ********************************************************************************************* --

USE [Testing]
GO

DECLARE @UserName NVARCHAR(256)
	, @PropertyName NVARCHAR(MAX)
	, @PropertyValue NVARCHAR(MAX)
	, @Field NVARCHAR(MAX)
	, @Value NVARCHAR(MAX)
	, @ValueString NVARCHAR(MAX)
	, @StartingPosition INT
	, @Length INT

DECLARE parseValues CURSOR LOCAL FOR
SELECT UserName, PropertyNames, PropertyValuesString 
FROM Testing.dbo.ClientDoctor 

OPEN parseValues
FETCH NEXT FROM parseValues INTO @UserName, @PropertyName, @PropertyValue

WHILE @@FETCH_STATUS = 0  
BEGIN   
	SET @ValueString = ''
	WHILE (LEN(@PropertyName) > 0)
	BEGIN
		IF (@PropertyName <> 'NULL')
		BEGIN
			SET @Field = LEFT(@PropertyName, CHARINDEX(':S:', @PropertyName)-1)
			SET @PropertyName = RIGHT(@PropertyName, LEN(@PropertyName) - CHARINDEX(':S:', @PropertyName) - 2)
			SET @StartingPosition = CAST(LEFT(@PropertyName, CHARINDEX(':', @PropertyName)-1) AS int)
			SET @PropertyName = RIGHT(@PropertyName, LEN(@PropertyName) - CHARINDEX(':', @PropertyName))
			SET @Length = COALESCE(CAST(LEFT(@PropertyName, CHARINDEX(':', @PropertyName) - 1) AS int), 0)
			IF (LEN(@PropertyValue) > (@StartingPosition + @Length))
				SET @Value = SUBSTRING(@PropertyValue, @StartingPosition + 1, @Length)
			ELSE
				SET @Value = ''
			SET @ValueString = @ValueString + ',' + @Field + '=' + @Value
			IF (LEN(@PropertyName) <= 3)
				SET @PropertyName = ''
			ELSE
				SET @PropertyName = RIGHT(@PropertyName, LEN(@PropertyName) - LEN(CAST(@Length as VARCHAR(10))) -1)
		END
		ELSE
		BEGIN
			SET @ValueString = ' NULL'
			SET @PropertyName = ''
		END
	END
	SET @ValueString = RIGHT(@ValueString, LEN(@ValueString) - 1)
	INSERT INTO dbo.ClientDoctorParsed (UserName, ValueString)
	VALUES (@UserName, @ValueString)
	FETCH NEXT FROM parseValues INTO @UserName, @PropertyName, @PropertyValue  
END  

CLOSE parseValues  
DEALLOCATE parseValues 
GO

-- ***************************************************************************************** --

SELECT 'UserName=' + [UserName] + ',' + [ValueString]
FROM [Testing].[dbo].[ClientDoctorParsed]
GO