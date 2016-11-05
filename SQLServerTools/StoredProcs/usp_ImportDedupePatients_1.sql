-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-08-27
-- Description:	Import Xifin Patient into 
--				SGNL_Internal and provide Sums 
--				of billable tests 
--				based on ICD Codes
-- =============================================
CREATE PROCEDURE [dbo].[usp_ImportDedupePatients] 

AS
BEGIN --> 1
	SET NOCOUNT ON;

	DECLARE
		@IcdCode			varchar(10)
		, @QNS				varchar(10)
		, @SpecimenType		varchar(100)
		, @OrderDate		datetimeoffset(7)
		, @CompletedDate	datetimeoffset(7)
		, @CaseNumber		varchar(20)
	DECLARE
		@NewPatientId		int
		, @QNScount			int
		, @count			int
	DECLARE
		@XifinPatientId		int
		, @FirstName		varchar(50)
		, @MiddleName		varchar(50)
		, @LastName			varchar(50)
		, @Suffix			varchar(50)
		, @Gender			varchar(50)
		, @SSN				varchar(50)
		, @DateOfBirth		datetime
		, @Ethnicity		varchar(50)
		, @MaritalStatus	varchar(50)
		, @PatientStatus	varchar(50)
		, @PatientEmail		varchar(100)
	DECLARE 
		@Address1			varchar(150)
		, @Address2			varchar(150)
		, @City				varchar(50)
		, @StateProvince	varchar(50)
		, @PostalCode		varchar(50)
	DECLARE
		@PhoneType			varchar(10)
		, @PhoneNumber		varchar(50)
		, @PhoneExtention	varchar(50)
	DECLARE
		@ClientId			int
		, @MRN				varchar(50)
	DECLARE
		@Payor1Id			int
		, @Payor2Id			int
	DECLARE @table TABLE (id int)
	DECLARE @GetDate		Date

	SET @GetDate = CONVERT(DATE,GETDATE())

	DECLARE MergePatients CURSOR LOCAL FOR
	SELECT 
		SC.CaseNumber, ICDCode, SC.QNS, XS.SpecimenTypeName
		, CONVERT(DATE, MAX(SA.OrderDate)), CONVERT(DATE, MAX(SA.CompletedDate))
		, MAX(SP.PatientId), COALESCE(MAX(SP.FirstName),''), COALESCE(MAX(SP.MiddleName),''), COALESCE(MAX(SP.LastName),''), COALESCE(MAX(SP.Suffix),'')
		, COALESCE(MAX(SP.Gender),''), COALESCE(MAX(SP.SocialSecurityNo),''), COALESCE(MAX(SP.DateOfBirth),'19000101'), COALESCE(MAX(SP.Ethnicity),'')
		, COALESCE(MAX(SP.MaritalStatus),''), COALESCE(MAX(SP.PatientStatus),''), COALESCE(MAX(SP.EmailAddress),'')
		, COALESCE(MAX(XADD.Address1),''), COALESCE(MAX(XADD.Address2),''), COALESCE(MAX(XADD.City),''), COALESCE(MAX(XADD.StateProvince),''), COALESCE(MAX(XADD.PostalCode),'')
		, COALESCE(MAX(XPH.PhoneType),''), COALESCE(MAX(XPH.PhoneNumber),''), COALESCE(MAX(XPH.Extension),'')
		, MAX(Client.id), COALESCE(MAX(SP.MRN),'')
		, MAX(Payor1.id), MAX(Payor2.id)
	FROM [SGNL_LIS].[dbo].[Patient] SP
		INNER JOIN [SGNL_LIS].[dbo].[Accession] SA ON SP.PatientId = SA.PatientId
		INNER JOIN [SGNL_LIS].[dbo].[LisCase] SC ON SA.AccessionId = SC.AccessionId
		LEFT OUTER JOIN [SGNL_LIS].[dbo].[Client] Client ON SA.ClientId = Client.id
		LEFT OUTER JOIN [XifinLIS].[dbo].[XIFIN_Address] XADD ON SP.PatientId = XADD.AddressId AND XADD.Category = 'P'
		LEFT OUTER JOIN [XifinLIS].[dbo].[XIFIN_Phone] XPH ON SP.PatientId = XPH.PhoneId AND XPH.Category = 'P'
		LEFT OUTER JOIN [SGNL_LIS].[dbo].[Payor] Payor1 ON SC.PayorId1 = Payor1.id
		LEFT OUTER JOIN [SGNL_LIS].[dbo].[Payor] Payor2 ON SC.PayorId2 = Payor2.id
		LEFT OUTER JOIN (
			SELECT C.CaseNo, T.TestOrderId, COALESCE(ICD10.Code, [SGNL_LIS].[dbo].[Icd9ToIcd10](ICD.Code)) AS ICDCode
				FROM [XifinLIS].[dbo].[XIFIN_Case] AS C
					INNER JOIN [XifinLIS].[dbo].XIFIN_TestOrder T ON C.CaseNo = T.CaseNo
					LEFT OUTER JOIN [XifinLIS].[dbo].[XIFIN_ICD9] ICD ON C.CaseNo = ICD.CaseNo AND T.TestOrderID = ICD.TestOrderID
					LEFT OUTER JOIN [XifinLIS].[dbo].[XIFIN_ICD10] ICD10 ON C.CaseNo = ICD10.CaseNo AND T.TestOrderID = ICD10.TestOrderId
		) ICD ON SC.CaseNumber = ICD.CaseNo
		LEFT OUTER JOIN [XifinLIS].[dbo].[XIFIN_Specimen] XS ON SC.CaseNumber = XS.CaseNo
		LEFT OUTER JOIN [dbo].[PatientXifinPatient] SgnlP ON SP.PatientId = SgnlP.XifinPatientId
	WHERE SgnlP.PatientId IS NULL
	GROUP BY SC.CaseNumber, ICDCode, SC.QNS, XS.SpecimenTypeName, SA.OrderDate
	ORDER BY SA.OrderDate ASC

	OPEN MergePatients

	FETCH NEXT FROM MergePatients INTO 
		@CaseNumber, @IcdCode, @QNS, @SpecimenType
		, @OrderDate, @CompletedDate
		, @XifinPatientId, @FirstName, @MiddleName, @LastName, @Suffix
		, @Gender, @SSN, @DateOfBirth, @Ethnicity
		, @MaritalStatus, @PatientStatus, @PatientEmail
		, @Address1, @Address2, @City, @StateProvince, @PostalCode
		, @PhoneType, @PhoneNumber, @PhoneExtention
		, @ClientId, @MRN
		, @Payor1Id, @Payor2Id


	WHILE @@FETCH_STATUS = 0

	BEGIN --> 2
		SELECT @NewPatientId = NULL
			, @QNScount = 0
			, @count = 0

		IF @QNS = 'true' 
			SET @QNScount = 1
		ELSE 
			SET @count = 1

		SELECT Top 1 @NewPatientId = PatientId 
		FROM PatientXifinPatient 
		WHERE XifinPatientId = @XifinPatientId

		IF @NewPatientId IS NULL
			SELECT TOP 1 @NewPatientId = PatientId 
			FROM [dbo].[udf_MatchPatient](@XifinPatientId, @FirstName, @MiddleName, @LastName, @Address1, @MRN, @ClientId, @Gender, @SSN, @DateOfBirth)

		IF @NewPatientId IS NOT NULL
		BEGIN --> 3

			IF NOT EXISTS(SELECT 1 FROM PatientXifinPatient WHERE PatientId = @NewPatientId AND XifinPatientId = @XifinPatientId)
				INSERT INTO PatientXifinPatient (PatientId, XifinPatientId)
				VALUES (@NewPatientId, @XifinPatientId)

			UPDATE [dbo].[Patient] SET 
				[FirstName] = @FirstName
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @FirstName <> ''
				AND [FirstName] <> @FirstName
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[LastName] = @LastName
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @LastName <> ''
				AND [LastName] <> @LastName
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[MiddleName] = @MiddleName
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @MiddleName <> ''
				AND [MiddleName] <> @MiddleName
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[Suffix] = @Suffix
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @Suffix <> ''
				AND [Suffix] <> @Suffix
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[SocialSecurityNo] = @SSN
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @SSN <> ''
				AND [SocialSecurityNo] <> @SSN
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[DateOfBirth] = @DateOfBirth
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE COALESCE(@DateOfBirth,'19000101') <> '19000101'
				AND [DateOfBirth] <> @DateOfBirth
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[Gender] = @Gender
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @Gender <> ''
				AND [Gender] <> @Gender
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[Ethnicity] = @Ethnicity
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @Ethnicity <> ''
				AND [Ethnicity] <> @Ethnicity
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[MaritalStatus] = @MaritalStatus
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @MaritalStatus <> ''
				AND [MaritalStatus] <> @MaritalStatus
				AND id = @NewPatientId

			UPDATE [dbo].[Patient] SET 
				[PatientStatus] = @PatientStatus
				,[LastModifiedDate] = @GetDate
				,[LastModifiedUser] = 'Patient Import'
			WHERE @PatientStatus <> ''
				AND [PatientStatus] <> @PatientStatus
				AND id = @NewPatientId

		END --< 3
		ELSE
		BEGIN --> 3
			INSERT INTO [dbo].[Patient]
						([FirstName], [LastName], [MiddleName], [Suffix]
						, [SocialSecurityNo], [DateOfBirth], [Gender], [Ethnicity]
						, [MaritalStatus], [PatientStatus]
						, [LastModifiedDate], [LastModifiedUser], [FlagForReview])
			OUTPUT INSERTED.id INTO @table
			VALUES
						(@FirstName, @LastName, @MiddleName, @Suffix
						, @SSN, @DateOfBirth, @Gender, @Ethnicity
						, @MaritalStatus, @PatientStatus
						, @GetDate, 'Patient Import', 0)

			SELECT TOP 1 @NewPatientId = id FROM @table
			DELETE FROM @table

		END --< 3

		IF NOT EXISTS(SELECT 1 FROM PatientXifinPatient WHERE PatientId = @NewPatientId AND XifinPatientId = @XifinPatientId)
			INSERT INTO PatientXifinPatient (PatientId, XifinPatientId)
			VALUES (@NewPatientId, @XifinPatientId)

		IF NOT EXISTS(SELECT 1 FROM PatientCaseNumber WHERE PatientId = @NewPatientId AND CaseNumber = @CaseNumber)
		BEGIN --> 3
			INSERT INTO PatientCaseNumber (PatientId, CaseNumber, IcdCode, QNS, OrderDate, CompletedDate)
			VALUES (@NewPatientId, @CaseNumber, @IcdCode, @QNS, @OrderDate, @CompletedDate)

			UPDATE [dbo].[PatientIcdCode] SET
				QnsRepeatCount = QnsRepeatCount + @QNScount
				, RepeatCount = RepeatCount + @count
			OUTPUT INSERTED.id INTO @table
			WHERE PatientId = @NewPatientId 
				AND COALESCE(IcdCode,'') = COALESCE(@IcdCode,'')
				AND COALESCE(@IcdCode, '') <> ''

			IF (NOT EXISTS(SELECT TOP 1 id FROM @table) AND COALESCE(@IcdCode, '') <>'')
			BEGIN --> 4

				INSERT INTO [dbo].[PatientIcdCode]
						([PatientId], [IcdCode], [SpecimenType], [QnsRepeatCount], [RepeatCount])
				VALUES
						(@NewPatientId, @IcdCode, @SpecimenType, @QNScount, @count)
			END --< 4
		DELETE FROM @table
		END --< 3
		ELSE
		BEGIN --> 3
			IF (NOT EXISTS(SELECT 1 FROM [dbo].[PatientIcdCode] WHERE PatientId = @NewPatientId AND IcdCode = @IcdCode AND SpecimenType = @SpecimenType)
				AND (COALESCE(@IcdCode, '') <> ''))
			BEGIN --> 4
				INSERT INTO [dbo].[PatientIcdCode]
						([PatientId], [IcdCode], [SpecimenType], [QnsRepeatCount], [RepeatCount])
				VALUES
						(@NewPatientId, @IcdCode, @SpecimenType, @QNScount, @count)
			END --< 4
		END --< 3

		IF (@ClientId IS NOT NULL 
			AND COALESCE(@MRN,'') <> ''
			AND NOT EXISTS(SELECT 1 FROM PatientClientMRN WHERE PatientId = @NewPatientId AND ClientId = @ClientId))
		BEGIN --> 3
			INSERT INTO PatientClientMRN (PatientId, ClientId, MRN, IcdCode)
			VALUES (@NewPatientId, @ClientId, @MRN, @IcdCode)
		END --< 3
			
		IF ((COALESCE(@Address1,'') <> '' OR COALESCE(@Address2,'') <> '' OR COALESCE(@City,'') <> '' OR COALESCE(@StateProvince,'') <> '' OR COALESCE(@PostalCode,'') <> '')
			AND NOT EXISTS(SELECT 1 FROM PatientAddress WHERE PatientId = @NewPatientId))
		BEGIN --> 3
			INSERT INTO PatientAddress(PatientId, Address1, Address2, City, StateProvince, PostalCode, CreatedDate)
			VALUES (@NewPatientId, @Address1, @Address2, @City, @StateProvince, @PostalCode, GetDate())
		END --< 3

		IF (COALESCE(@PatientEmail,'') <> '' AND COALESCE(@PatientEmail, 'none') <> 'none'
			AND NOT EXISTS(SELECT 1 FROM PatientEmailAddress WHERE PatientId = @NewPatientId AND EmailAddress = @PatientEmail))
		BEGIN --> 3
			INSERT INTO PatientEmailAddress(PatientId, EmailAddress)
			VALUES (@NewPatientId, @PatientEmail)
		END --< 3

		IF ((COALESCE(@PhoneType,'') <> '' OR COALESCE(@PhoneNumber,'') <> '' OR COALESCE(@PhoneExtention,'') <> '')
			AND NOT EXISTS(SELECT 1 FROM PatientPhone WHERE PatientId = @NewPatientId AND PhoneType = @PhoneType))
		BEGIN --> 3
			INSERT INTO PatientPhone(PatientId, PhoneType, PhoneNumber, Extention, CreatedDate)
			VALUES (@NewPatientId, @PhoneType, @PhoneNumber, @PhoneExtention, Getdate())
		END --< 3

		IF (COALESCE(@Payor1Id, 9999) <> 9999
			AND NOT EXISTS(SELECT 1 FROM PatientPayor WHERE PatientId = @NewPatientId AND PayorId = @Payor1Id AND COALESCE(IcdCode,'') = COALESCE(@IcdCode,'')))
		BEGIN --> 3
			INSERT INTO PatientPayor (PatientId, PayorId, IcdCode)
			VALUES (@NewPatientId, @Payor1Id, @IcdCode)
		END --< 3

		IF (COALESCE(@Payor2Id, 9999) <> 9999
			AND NOT EXISTS(SELECT 1 FROM PatientPayor WHERE PatientId = @NewPatientId AND PayorId = @Payor2Id AND COALESCE(IcdCode,'') = COALESCE(@IcdCode,'')))
		BEGIN --> 3
			INSERT INTO PatientPayor (PatientId, PayorId, IcdCode)
			VALUES (@NewPatientId, @Payor2Id, @IcdCode)
		END --< 3

		FETCH NEXT FROM MergePatients INTO 
			@CaseNumber, @IcdCode, @QNS, @SpecimenType
			, @OrderDate, @CompletedDate
			, @XifinPatientId, @FirstName, @MiddleName, @LastName, @Suffix
			, @Gender, @SSN, @DateOfBirth, @Ethnicity
			, @MaritalStatus, @PatientStatus, @PatientEmail
			, @Address1, @Address2, @City, @StateProvince, @PostalCode
			, @PhoneType, @PhoneNumber, @PhoneExtention
			, @ClientId, @MRN
			, @Payor1Id, @Payor2Id
	END --< 2
END --< 1