-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-08-26
-- Description:	Compare Patient Demographics to find repeat Patient ID's
-- =============================================
CREATE FUNCTION [dbo].[udf_MatchPatient] 
(
	@XifinPatientId	int
	, @FirstName	varchar(50)
	, @MiddleName	varchar(50)
	, @LastName		varchar(50)
	, @Address1		varchar(50)
	, @MRN			varchar(50)
	, @Client		varchar(50)
	, @Gender		varchar(50)
	, @SSN			varchar(50)
	, @DateOfBirth	datetime
)
RETURNS 
@Patients TABLE 
(
	PatientId int
)
AS
BEGIN

	SELECT 
		@XifinPatientId	= COALESCE(LTRIM(RTRIM(@XifinPatientId)), '')
		, @FirstName	= COALESCE(LTRIM(RTRIM(@FirstName)), '')
		, @MiddleName	= COALESCE(LTRIM(RTRIM(@MiddleName)), '')
		, @LastName		= COALESCE(LTRIM(RTRIM(@LastName)), '')
		, @Address1		= COALESCE(LTRIM(RTRIM(@Address1)), '')
		, @MRN			= COALESCE(LTRIM(RTRIM(@MRN)), '')
		, @Client		= COALESCE(LTRIM(RTRIM(@Client)), '')
		, @Gender		= COALESCE(LTRIM(RTRIM(@Gender)), '')
		, @SSN			= COALESCE(LTRIM(RTRIM(@SSN)), '')
		, @DateOfBirth	= COALESCE(CONVERT(DATE,@DateOfBirth), '19000101')

	DECLARE @AddressSearch varchar(50)
	SET @AddressSearch = dbo.udf_FirstTwoWords(@Address1)

	-- Find { SSN + DOB } matches
	IF (@DateOfBirth <> '19000101' 
		AND @SSN <> '')
	INSERT INTO @Patients (PatientId)
	SELECT P.id
	FROM Patient P
	WHERE COALESCE(P.SocialSecurityNo,'') <> ''
		AND P.DateOfBirth IS NOT NULL
		AND P.SocialSecurityNo = @SSN
		AND CONVERT(date, P.DateOfBirth) = @DateOfBirth

	-- Find { LastName, DOB, MRN + Client, Gender } Matches
	IF (@LastName <> ''
		AND @MRN <> ''
		AND @DateOfBirth <> '19000101'
		AND @Client <> ''
		AND @Gender <> ''
		)
		INSERT INTO @Patients (PatientId)
		SELECT P.id 
		FROM Patient P
			INNER JOIN PatientClientMRN PCM ON P.id = PCM.PatientId
				AND PCM.ClientId = @Client
				AND PCM.MRN = @MRN
		WHERE COALESCE(P.LastName,'') <> ''
			AND P.DateOfBirth IS NOT NULL
			AND P.LastName = @LastName
			AND CONVERT(date, P.DateOfBirth) = @DateOfBirth
			AND P.Gender = @Gender

	-- Find { DOB, MLN + Client, Gender } Matches
	IF (@MRN <> ''
		AND @DateOfBirth <> '19000101'
		AND @Client <> ''
		AND @Gender <> ''
		)
		INSERT INTO @Patients (PatientId)
		SELECT P.id 
		FROM Patient P
			INNER JOIN PatientClientMRN PCM ON P.id = PCM.PatientId
				AND PCM.ClientId = @Client
				AND PCM.MRN = @MRN
		WHERE P.DateOfBirth IS NOT NULL
			AND COALESCE(P.Gender,'') <> ''
			AND P.Gender = @Gender
			AND CONVERT(date, P.DateOfBirth) = @DateOfBirth

	-- Find { LastName, MRN + Client, Gender } Matches
	IF (@LastName <> ''
		AND @MRN <> ''
		AND @Client <> ''
		AND @Gender <> ''
		)
		INSERT INTO @Patients (PatientId)
		SELECT P.id 
		FROM Patient P
			INNER JOIN PatientClientMRN PCM ON P.id = PCM.PatientId
				AND PCM.ClientId = @Client
				AND PCM.MRN = @MRN
		WHERE COALESCE(P.LastName,'') <> ''
			AND COALESCE(P.Gender,'') <> ''
			AND P.LastName = @LastName
			AND P.Gender = @Gender

	-- Find { LastName, DOB, MRN + Client } Matches
	IF (@LastName <> ''
		AND @MRN <> ''
		AND @DateOfBirth <> '19000101'
		AND @Client <> ''
		)
		INSERT INTO @Patients (PatientId)
		SELECT P.id 
		FROM Patient P
			INNER JOIN PatientClientMRN PCM ON P.id = PCM.PatientId
				AND PCM.ClientId = @Client
				AND PCM.MRN = @MRN
		WHERE COALESCE(P.LastName,'') <> ''
			AND P.DateOfBirth IS NOT NULL
			AND P.LastName = @LastName
			AND CONVERT(date, P.DateOfBirth) = @DateOfBirth

	-- Combined Method - Find { Similar(FirstName), Similar(LastName), DOB, Similar(Address1) } Matches
	INSERT INTO @Patients (PatientId)
	SELECT P.id 
	FROM Patient P
		INNER JOIN PatientAddress PA ON P.id = PA.PatientId
			AND (dbo.udf_String_SimilarityDistance(PA.Address1, @Address1) <= 3) 
	WHERE CONVERT(date, P.DateOfBirth) = @DateOfBirth
		AND 
		(	(dbo.udf_String_SimilarityDistance(P.FirstName, @FirstName) <= 3
				AND dbo.udf_String_SimilarityDistance(P.LastName, @LastName) <= 3
			) 
			OR (DIFFERENCE(P.FirstName, @FirstName) >= 3 
				AND DIFFERENCE(P.LastName, @LastName) >= 3 
				AND DIFFERENCE(dbo.udf_FirstTwoWords(PA.Address1), @AddressSearch) >= 3
			)
			/*
			OR (SOUNDEX(P.FirstName) = SOUNDEX(@FirstName)
				AND SOUNDEX(P.LastName) = SOUNDEX(@LastName)
				AND SOUNDEX(dbo.udf_FirstTwoWords(PA.Address1)) = SOUNDEX(@AddressSearch)
			)
			*/
			OR ((P.FirstName LIKE ('%' + @FirstName + '%')
					OR @FirstName LIKE ('%' + P.FirstName + '%'))
				AND (P.LastName LIKE ('%' + @LastName + '%')
					OR @LastName LIKE ('%' + P.LastName + '%'))
				AND (dbo.udf_FirstTwoWords(PA.Address1) LIKE ('%' + @AddressSearch)
					OR @AddressSearch LIKE ('%' + dbo.udf_FirstTwoWords(PA.Address1)))
				)
		)

/*

	-- Find XifinPatientId Matches
	INSERT INTO @Patients (PatientId)
	SELECT PatientId 
	FROM PatientXifinPatient
	WHERE XifinPatientId = @XifinPatientId
*/
/*
	-- #1 Method - Find { Similar(FirstName), Similar(LastName), DOB, Similar(Address1) } Matches
	INSERT INTO @Patients (PatientId)
	SELECT P.id 
	FROM Patient P
		INNER JOIN PatientAddress PA ON P.id = PA.PatientId
			AND (dbo.udf_String_SimilarityDistance(PA.Address1, @Address1) <= 3) 
	WHERE CONVERT(date, P.DateOfBirth) = CONVERT(date, @DateOfBirth)
		AND (dbo.udf_String_SimilarityDistance(P.FirstName, @FirstName) <= 3) 
		AND (dbo.udf_String_SimilarityDistance(P.LastName, @LastName) <= 3) 

	-- #2 Method - Find { Similar(FirstName), Similar(LastName), DOB, Similar(Address1) } Matches
	INSERT INTO @Patients (PatientId)
	SELECT P.id 
	FROM Patient P
		INNER JOIN PatientAddress PA ON P.id = PA.PatientId
			AND DIFFERENCE(PA.Address1, @Address1) >= 3
	WHERE CONVERT(date, P.DateOfBirth) = CONVERT(date, @DateOfBirth)
		AND DIFFERENCE(P.FirstName, @FirstName) >= 3 
		AND DIFFERENCE(P.LastName, @LastName) >= 3 
*/

	RETURN 
END