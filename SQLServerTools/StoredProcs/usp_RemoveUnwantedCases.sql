-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-25
-- Description:	Delete test Cases from all levels of Warehouse
-- =============================================
CREATE PROCEDURE [dbo].[usp_RemoveUnwantedCases] 
	-- Add the parameters for the stored procedure here
	@CaseNumber			varchar(20)		= ''
	, @AccessionId		int				= 0
	, @ClientCode		varchar(50)		= ''
	, @ClientId			int				= 0
	, @FacilityId		int				= 0
	, @DeleteBilled		bit				= 0
	, @DeleteClient		bit				= 0
	, @DeleteFacility	bit				= 0
	, @CaseList			CaseListType	READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrorMessage		VARCHAR(256)
	DECLARE @CaseListVar		CaseListType
	DECLARE @BilledCaseList		CaseListType
	DECLARE @ClientList 		TABLE (ClientCode	VARCHAR(50), ClientName		VARCHAR(250))
	DECLARE @FacilityList		TABLE (FacilityId	INT,		 FacilityName	VARCHAR(250))
	DECLARE @CaseListPrint		VARCHAR(MAX)
	DECLARE @BilledListPrint	VARCHAR(MAX)
	DECLARE @ClientListPrint	VARCHAR(MAX)
	DECLARE @FacilityListPrint	VARCHAR(MAX)
	DECLARE @CRLF				CHAR(2)

	SET @CRLF = CHAR(13) + CHAR(10)
	
	-- **************************************************************************** --
	-- *************			Create Delete Parameters	  		*************** --
	-- **************************************************************************** --

	INSERT INTO @CaseListVar
	SELECT CaseNumber FROM @CaseList

	IF COALESCE(@CaseNumber, '') <> ''
		INSERT INTO @CaseListVar
		VALUES (@CaseNumber)

	IF @AccessionId <> 0
		INSERT INTO @CaseListVar
		SELECT DISTINCT CaseNo
		FROM XifinLIS.dbo.XIFIN_Case
		WHERE AccessionId = @AccessionId

	IF COALESCE(@ClientCode, '') <> ''
		INSERT INTO @CaseListVar
		SELECT DISTINCT CaseNo
		FROM XifinLIS.dbo.XIFIN_CASE C
			INNER JOIN XifinLIS.dbo.XIFIN_Accession A ON C.AccessionId = A.AccessionId
		WHERE A.ClientCode = @ClientCode

	IF (@ClientId <> 0)
		INSERT INTO @CaseListVar
		SELECT DISTINCT CaseNo
		FROM XifinLIS.dbo.XIFIN_Case C
			INNER JOIN XifinLIS.dbo.XIFIN_Accession A ON C.AccessionId = A.AccessionId
		WHERE A.ClientCode = (
							SELECT ClientCode
							FROM SGNL_LIS.dbo.Client
							WHERE id = @ClientId
							)

	IF (@FacilityId <> 0)
		INSERT INTO @CaseListVar
		SELECT CaseNo
		FROM XifinLIS.dbo.XIFIN_CASE C
			INNER JOIN XifinLIS.dbo.XIFIN_Accession A ON C.AccessionId = A.AccessionId
		WHERE A.FacilityId = @FacilityId

	IF (@DeleteClient = 1)
	BEGIN --> 2
		INSERT INTO @ClientList
		SELECT DISTINCT ClientCode, Name
		FROM SGNL_LIS.dbo.Client Cl
			INNER JOIN SGNL_LIS.dbo.Accession A ON Cl.ClientId = A.ClientId
			INNER JOIN SGNL_LIS.dbo.LisCase C ON A.AccessionId = C.AccessionId
			INNER JOIN @CaseListVar CLV ON C.CaseNumber = CLV.CaseNumber

		IF (@ClientCode <> '')
			INSERT INTO @ClientList
			SELECT DISTINCT ClientCode, Name
			FROM SGNL_LIS.dbo.Client
			WHERE ClientCode =  @ClientCode
	END --< 2

	IF (@DeleteFacility = 1)
	BEGIN --> 2
		INSERT INTO @FacilityList
		SELECT DISTINCT F.FacilityId, F.FacilityName
		FROM SGNL_LIS.dbo.Facility F
			INNER JOIN SGNL_LIS.dbo.Accession A ON F.FacilityId = A.FacilityId
			INNER JOIN SGNL_LIS.dbo.LisCase C ON A.AccessionId = C.AccessionId
			INNER JOIN @CaseListVar CLV ON C.CaseNumber = CLV.CaseNumber

		IF (@FacilityId <> 0)
			INSERT INTO @FacilityList
			SELECT @FacilityId, FacilityName
			FROM SGNL_LIS.dbo.Facility 
			WHERE FacilityId = @FacilityId
	END --< 2

	-- **************************************************************************** --
	-- *************			Find Cases Already Billed	  		*************** --
	-- **************************************************************************** --

	INSERT INTO @BilledCaseList
	SELECT CaseNumber
	FROM SGNL_FINANCE.dbo.BilledCase
	WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

	-- Remove Cases that are already billed if option to remove billed cases is not enforced
	IF (@DeleteBilled <> 1)
		DELETE C
		FROM @CaseListVar C
			INNER JOIN @BilledCaseList B ON C.CaseNumber = B.CaseNumber

	-- **************************************************************************** --
	-- *************					BEGIN DELETES		  		*************** --
	-- **************************************************************************** --

	IF EXISTS(SELECT 1 FROM @CaseListVar)
	BEGIN --> 2
		BEGIN TRANSACTION RemoveCases

		-- ************************************************************************ --
		-- *********                  XifinLIS								******* --
		-- ************************************************************************ --

		DELETE
		FROM XifinLIS.dbo.XIFIN_TestOrderSpecimen
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_Result
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_Report
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_ICD9
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_ICD10
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_TestOrder
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_Specimen
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_PatientInsurance
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_CaseInsurance
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM XifinLIS.dbo.XIFIN_Case
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE A
		FROM XifinLIS.dbo.XIFIN_Accession A
			INNER JOIN XifinLIS.dbo.XIFIN_Case C ON A.AccessionId = C.AccessionId
		WHERE CaseNo IN (SELECT CaseNumber FROM @CaseListVar)
			AND A.AccessionId NOT IN (
							SELECT AccessionId 
							FROM XifinLIS.dbo.XIFIN_Case 
							WHERE CaseNo NOT IN (Select CaseNumber FROM @CaseListVar)
							)

		-- ************************************************************************ --
		-- *********                  SGNL_LIS								******* --
		-- ************************************************************************ --

		DELETE S
		FROM SGNL_LIS.dbo.Specimen S
			INNER JOIN SGNL_LIS.dbo.LisCase C ON S.CaseId = C.id
		WHERE C.CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE 
		FROM SGNL_LIS.dbo.StudyId 
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE 
		FROM SGNL_LIS.dbo.PatientInsurance
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM SGNL_LIS.dbo.CaseResults
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM SGNL_LIS.dbo.CELHeaderInfo
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM SGNL_LIS.dbo.LisCase
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE A
		FROM SGNL_LIS.dbo.Accession A
			INNER JOIN SGNL_LIS.dbo.LisCase C ON A.AccessionId = C.AccessionId
		WHERE C.CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)
			AND A.AccessionId NOT IN (
				SELECT AccessionId 
				FROM SGNL_LIS.dbo.LisCase 
				WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)
			) 

		-- ************************************************************************ --
		-- *********                  SGNL_INTERNAL							******* --
		-- ************************************************************************ --

		DELETE 
		FROM SGNL_INTERNAL.dbo.CaseClassification
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE 
		FROM SGNL_INTERNAL.dbo.PatientCaseNumber
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		-- ************************************************************************ --
		-- *********                  SGNL_FINANCE							******* --
		-- ************************************************************************ --
		DELETE BE
		FROM SGNL_FINANCE.dbo.BilledErrors BE
			INNER JOIN SGNL_FINANCE.dbo.BilledCase BC ON BE.BilledCasesId = BC.Id
		WHERE BC.CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM SGNL_FINANCE.dbo.BilledCase
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE CN
		FROM SGNL_FINANCE.dbo.CaseNote CN
			INNER JOIN SGNL_FINANCE.dbo.CasePayment CP ON CN.CasePaymentId = CP.id
		WHERE CP.CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)

		DELETE
		FROM SGNL_FINANCE.dbo.CasePayment
		WHERE CaseNumber IN (SELECT CaseNumber FROM @CaseListVar)
			
		DELETE CT
		FROM SGNL_FINANCE.dbo.CaseNumberTransaction CT
			INNER JOIN SGNL_LIS.dbo.LisCase C ON CT.CaseNumber = C.CaseNumber
		WHERE C.CaseNumber IN (Select CaseNumber FROM @CaseListVar)

		COMMIT TRANSACTION RemoveCases

		-- **************************************************************************** --
		-- ************		Display List Of Clients to be Deleted			*********** --
		-- **************************************************************************** --

		SELECT @ClientListPrint = SGNL_LIS.dbo.GROUP_CONCAT_D(ClientCode + ' - ' + ClientName, @CRLF)
		FROM @ClientList
		
		SET @ClientListPrint = 'Clients to be Deleted: ' + @CRLF + @CaseListPrint + @CRLF
		PRINT @ClientListPrint

		SELECT 'Client Deleted:', ClientCode, ClientName
		FROM @ClientList

		-- **************************************************************************** --
		-- ************		Display List Of Facilities to be Deleted		*********** --
		-- **************************************************************************** --

		SELECT @FacilityListPrint = SGNL_LIS.dbo.GROUP_CONCAT_D(CAST(FacilityId AS VARCHAR(50)) + ' - ' + FacilityName, @CRLF)
		FROM @FacilityList
		
		SET @FacilityListPrint = 'Facilities to be Deleted: ' + @CRLF + @FacilityListPrint + @CRLF
		PRINT @FacilityListPrint

		SELECT 'Facility Deleted:', CAST(FacilityId AS varchar(50)), FacilityName
		FROM @FacilityList

		-- **************************************************************************** --

		IF (@DeleteClient = 1)
		BEGIN --> 3
			DECLARE DeleteClients CURSOR LOCAL FOR
			SELECT DISTINCT ClientCode
			FROM @ClientList

			OPEN DeleteClients

			FETCH NEXT FROM DeleteClients INTO @ClientCode
			WHILE @@FETCH_STATUS = 0
			BEGIN --> 4
				EXEC dbo.usp_RemoveUnwantedClient NULL, @ClientCode
				FETCH NEXT FROM DeleteClients INTO @ClientCode
			END --< 4
		END --< 3

		IF (@DeleteFacility = 1)
		BEGIN --> 3
			DECLARE DeleteFacilities CURSOR LOCAL FOR
			SELECT DISTINCT FacilityId
			FROM @FacilityList

			OPEN DeleteFacilities

			FETCH NEXT FROM DeleteClients INTO @FacilityId
			WHILE @@FETCH_STATUS = 0
			BEGIN --> 4
				EXEC dbo.usp_RemoveUnwantedFacility @FacilityId
			END --< 4
		END --< 3

		-- **************************************************************************** --
		-- ****************		Display List Of Cases Deleted			*************** --
		-- **************************************************************************** --

		SELECT @CaseListPrint = SGNL_LIS.dbo.GROUP_CONCAT_D(CaseNumber, @CRLF)
		FROM @CaseListVar
		
		SET @CaseListPrint = 'Cases Deleted: ' + @CRLF + @CaseListPrint + @CRLF
		PRINT @CaseListPrint

		SELECT 'Case Deleted:', CaseNumber
		FROM @CaseListVar

		-- **************************************************************************** --
		-- ************		Display List Of Cases Billed and Not Deleted	*********** --
		-- **************************************************************************** --

		SELECT @BilledListPrint = SGNL_LIS.dbo.GROUP_CONCAT_D(CaseNumber, @CRLF)
		FROM @BilledCaseList
		
		SET @BilledListPrint = 'Cases Already Billed: ' + @CRLF + @BilledListPrint + @CRLF
		PRINT @BilledListPrint

		SELECT 'Case Already Billed:', CaseNumber
		FROM @BilledCaseList

		-- **************************************************************************** --

		BEGIN TRY
			EXEC SGNL_LIS.dbo.usp_UpdateLisWarehouse @CaseNumber = NULL
		END TRY
		BEGIN CATCH
			EXEC usp_InsertErrorDetails
			ROLLBACK TRANSACTION RemoveCases
		END CATCH
	END
	ELSE BEGIN
		IF EXISTS(SELECT 1 FROM @BilledCaseList)
		BEGIN
			SELECT @BilledListPrint = SGNL_LIS.dbo.GROUP_CONCAT_D(CaseNumber, @CRLF)
			FROM @BilledCaseList
			SET @ErrorMessage = 'Cases specified for removal have already been billed:' + @CRLF
				+ @BilledListPrint
		END
		ELSE BEGIN
		    SET @ErrorMessage = 'No cases specified for removal.' + @CRLF + ' '
		END
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
	END
END