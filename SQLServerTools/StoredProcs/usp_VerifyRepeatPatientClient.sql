-- =============================================
-- Author:		Patrick de los Reyes
-- Create date: 2015-11-18
-- Description:	Return All Cases for a patient who has a case in the time period specified.
-- =============================================
CREATE PROCEDURE [dbo].[usp_VerifyRepeatPatientClient] 
	-- Add the parameters for the stored procedure here
	@StartDate			DATETIME 
	, @EndDate			DATETIME
	, @ClientName       VARCHAR(128)
	, @PayorName		VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;

	SET @StartDate = COALESCE(@StartDate, DATEADD(WW, -3, GETDATE()))
	SET @EndDate = COALESCE(@EndDate, GETDATE())
	SET @ClientName = COALESCE(@ClientName, '%')
	SET @PayorName = COALESCE(@PayorName, '%')

	SELECT 
			P.id									AS SgnlPatientId
		   , XP.XifinPatientId						AS XifinPatientId
		   , AllCases.CaseNumber					AS CaseNumber
		   , MAX(AllCases.ICD9Codes)				AS ICD9Codes
		   , MAX(AllCases.ICD10Codes)				AS ICD10Codes
		   , MAX(AllCases.ComputedICD10Codes)		AS ComputedICD10Codes
		   , MAX(AllCases.QNS)						AS QNS
		   , AllCases.RepeatCount                   AS RepeatCount
		   , CAST(A.OrderDate AS DATETIME)			AS OrderDate
		   , MAX(AllCases.Ins1)						AS Ins1
		   , MAX(AllCases.Ins2)						AS Ins2
		   , MAX(P.FirstName)						AS FirstName
		   , MAX(P.LastName)						AS LastName
		   , MAX(P.SocialSecurityNo)				AS SSN
		   , MAX(AllCases.Name)                     AS ClientName
		   , MAX(PMRN.MRN)                          AS MRN
		   , CASE WHEN MAX(P.DateOfBirth) = '1900-01-01' 
				  THEN NULL
				  ELSE MAX(P.DateOfBirth)
				  END                               AS DOB
		   , MAX(P.Gender)                          AS Gender
		   , MAX(AllCases.ProgramGroup)				AS ProgramGroup
		   , MAX(AllCases.BillingClassification)	AS BillingClassification
		   , MAX(AllCases.BillableStatus)			AS BillStatus
	FROM SGNL_INTERNAL.dbo.Patient P
		   INNER JOIN SGNL_INTERNAL.dbo.PatientXifinPatient XP ON P.id = XP.PatientId
		   INNER JOIN SGNL_LIS.dbo.Accession A ON XP.XifinPatientId = A.PatientId
		   INNER JOIN SGNL_LIS.dbo.LisCase C ON A.AccessionId = C.AccessionId
		   LEFT OUTER JOIN SGNL_LIS.dbo.Payor Payor1 ON C.PayorId1 = Payor1.id
		   LEFT OUTER JOIN SGNL_LIS.dbo.Payor Payor2 ON C.PayorId2 = Payor2.id
		   LEFT OUTER JOIN SGNL_INTERNAL.dbo.PatientAddress PA ON P.id = PA.PatientId
		   LEFT OUTER JOIN SGNL_INTERNAL.dbo.PatientClientMRN PMRN ON P.id = PMRN.PatientId
		   LEFT OUTER JOIN SGNL_LIS.dbo.Client CL ON A.ClientId = CL.id
		   LEFT OUTER JOIN (
				  SELECT DISTINCT A.PatientId, C.CaseNumber, C.ICD9Codes, C.ICD10Codes, C.ComputedICD10Codes, C.RepeatCount, C.QNS
									, CL.Name , CC.ProgramGroup, CC.BillableStatus, CC.BillingClassification
									, Y.PayorName AS Ins1, X.PayorName AS Ins2
				  FROM SGNL_LIS.dbo.LisCase C
						INNER JOIN SGNL_LIS.dbo.Accession A ON C.AccessionId = A.AccessionId
						LEFT OUTER JOIN SGNL_LIS.dbo.Payor Y ON C.PayorId1 = Y.id
						LEFT OUTER JOIN SGNL_LIS.dbo.Payor X ON C.PayorId2 = X.id
						LEFT OUTER JOIN SGNL_LIS.dbo.Client CL ON A.ClientId = CL.id
						LEFT OUTER JOIN SGNL_INTERNAL.dbo.CaseClassification CC ON C.CaseNumber = CC.CaseNumber
						 GROUP BY C.CaseNumber, A.PatientId, C.ICD9Codes, C.ICD10Codes, C.ComputedICD10Codes, C.RepeatCount, C.QNS
									, CL.Name , CC.ProgramGroup, CC.BillableStatus, CC.BillingClassification
									, Y.PayorName, X.PayorName
				  ) AllCases ON A.PatientId = AllCases.PatientId
	WHERE 1=1
			AND CL.Name LIKE '%' + @ClientName + '%'
			AND (Payor1.PayorName LIKE '%' + @PayorName + '%'
				OR Payor2.PayorName LIKE '%' + @PayorName + '%')
		   AND A.OrderDate > @StartDate
		   AND A.OrderDate < @EndDate
	GROUP BY AllCases.CaseNumber, P.id, A.OrderDate, XP.XifinPatientId, CL.Name, AllCases.RepeatCount
	ORDER BY XP.XifinPatientId, A.OrderDate ASC

END