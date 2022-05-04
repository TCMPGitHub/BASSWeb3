USE [BassWebTest]
GO

/****** Object:  StoredProcedure [dbo].[spGetInmateProfile]    Script Date: 8/10/2017 9:44:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Drop Procedure [spGetInmateProfile]
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGetInmateProfile]
	@EpisodeID int  = 0,
	@CurrentUserID int,
	@All bit = 0
AS
BEGIN
--DECLARE @CDCRNum varchar(6) =  ''  -- 'BF2343'
--DECLARE @EpisodeID int 
DECLARE @SomsUploadID int
DECLARE @CDCRNum varchar(6) = ''
DECLARE @BenefitWorkerID int
DECLARE @OffenderID int = 0
DECLARE @MEpisodeID int  = 0
--DECLARE @CurrentUserID int = 481 --1053
DECLARE @SsiDeterminString nvarchar(200) ='DPW,DPO,DPM,DNM,DPH,DPS,DPV,DKD,DD1,DD2,DD3,DSH,ICF,APU,MHC,EOP,ACU'

IF @EpisodeID = 0
BEGIN
   IF EXISTS(SELECT 1 FROM dbo.CaseAssignment WHERE BenefitWorkerID  = @CurrentUserID AND UnAssignedDateTime IS NULL)
      SELECT @EpisodeID = EpisodeID, @OffenderID  = OffenderID, @CDCRNum = CDCRNum, @SomsUploadID = SomsUploadID FROM dbo.Episode WHERE EpisodeID  =
        (SELECT top 1 EpisodeID FROM dbo.CaseAssignment WHERE BenefitWorkerID  = @CurrentUserID AND UnAssignedDateTime IS NULL ORDER BY AssignedDateTime DESC) 
END
ELSE 
    SELECT @EpisodeID = EpisodeID, @OffenderID  = OffenderID, @CDCRNum = CDCRNum, @SomsUploadID = SomsUploadID FROM dbo.Episode WHere EpisodeID = @EpisodeID


IF @OffenderID  > 0 
  SET @MEpisodeID  =  (SELECT MAX(EpisodeID) FROM dbo.Episode WHERE OffenderID  =  @OffenderID)

SELECT @BenefitWorkerID = BenefitWorkerID FROM dbo.CaseAssignment WHERE EpisodeID = @EpisodeID AND UnAssignedDateTime IS NULL

IF @SomsUploadID > 0
BEGIN
SELECT CDCNumber AS CDCRNum, (CASE WHEN Unit = 'PRCCF' OR Unit ='PUCCF' THEN 
		     (SELECT TOP 1 FacilityID FROM Facility 
			   WHERE OrgCommonID = Unit and Disabled <> 1 and substring(SomsLoc, CHARINDEX( '-', SomsLoc)+1, len(SomsLoc)) = substring(Loc, CHARINDEX( '-', Loc)+1, len(Loc)))
             ELSE (SELECT TOP 1 FacilityID FROM Facility WHERE OrgCommonID = Unit and Disabled <> 1) END)CustodyFacilityID
      ,(CASE WHEN ScheduledReleaseDate IS NOT NULL THEN Convert(varchar,ScheduledReleaseDate, 101) ELSE null END)SomsReleaseDate, InmateLastName AS LastName ,InmateFirstName AS FirstName
      ,(select GenderID from Gender where Code= InmateSexCode)GenderID, CellBed AS Housing, SSNum AS SSN,FileDate,InmateDateOfBirth AS DOB
	  ,(CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END)EOP
	  ,(CASE WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END)CCCMS
	  ,(CASE WHEN len(ISNULL(PENALCODE, '')) >0 THEN 1 ELSE 0 END)PC290, 0 AS PC457 
      ,(CASE WHEN DevelopDisabledEvaluation in ('DD1', 'DD2', 'DD3') THEN 1 ELSE 0 END)DevDisabled
      ,(CASE WHEN ISNULL(DPPHearingCode,'')<>'' or ISNULL(DPPMobilityCode, '')<>'' or ISNULL(DPPSpeechCode, '')<>'' or ISNULL(DPPVisionCode, '')<>'' THEN 1 ELSE 0 END)PhysDisabled
      ,(CASE WHEN DPPHearingCode = 'DPH' OR DPPMobilityCode in ('DPM', 'DPO', 'DPW') OR DPPSpeechCode = 'DPS' OR DPPVisionCode = 'DPV'  THEN 1 ELSE 0 END )MedPlacement
      ,(CASE WHEN  (CHARINDEX(DPPMobilityCode, @SsiDeterminString) > 0  OR  
					CHARINDEX(DPPHearingCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPSpeechCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPVisionCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DevelopDisabledEvaluation, @SsiDeterminString) > 0  OR
					CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0) AND DevelopDisabledEvaluation <> 'NCF' THEN 1 ELSE 0 END)SSI, (CASE WHEN Lifer = 'Y' THEN 1 ELSE 0 END)Lifer
      ,(CASE WHEN ISNULl(CountyOfRelease, '') <> '' AND EXISTS(select 1 from County where Name =CountyOfRelease) THEN 
			         (select CountyID from County where Name =CountyOfRelease) ELSE NULL END)ReleaseCountyID, ISNULL(PAROLEUNIT, '')ParoleUnit
      ,(CASE WHEN PAROLEAGENTLASTNAME is NOT null AND PAROLEAGENTLASTNAME <> '' THEN
			 PAROLEAGENTLASTNAME +  ', ' + ISNULL(PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(PAROLEAGENTMIDDLENAME, '')
			 ELSE ISNULL(PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(PAROLEAGENTMIDDLENAME, '') END)ParoleAgent
FROM [dbo].[SomsRecord] WHERE CDCNumber = @CDCRNum AND SomsUploadID = @SomsUploadID
END
ELSE
BEGIN
 SELECT @CDCRNum AS CDCRNum,  null AS CustodyFacilityID, null AS SomsReleaseDate,''LastName,'' AS FirstName, null AS GenderID, null AS Housing, null AS SSN
        ,null AS FileDate, null AS DOB,0 AS EOP, 0 AS CCCMS, 0 AS PC290, 0 AS PC457, 0 AS DevDisabled, 0 AS PhysDisabled, 0 AS MedPlacement, 0 AS SSI
		,0 AS Lifer, null AS ReleaseCountyID, ''ParoleUnit,''ParoleAgen
END

IF ISNULL(@EpisodeID, 0) > 0
BEGIN
SELECT e.EpisodeID, e.CDCRNum, e.OffenderID, (CASE WHEN ISNULL(@SomsUploadID, 0) > 0 THEN 1 ELSE 0 END)SomsDataExists, (CASE WHEN o.ReviewStatus = 1 THEN 1 ELSE 0 END)SomsFlagged, 
       (CASE WHEN ISNULL(@BenefitWorkerID, 0) > 0 THEN 1 ELSE 0 END)CaseAssigned, o.LastName, o.FirstName, o.MiddleName,o.PC290, o.PC457, o.USVet, o.ReviewStatus,
	   o.SSN, o.DOB, o.GenderID, o.LongTermMedCare, o.Hospice, o.AssistedLiving, o.HIVPos, o.ChronicIllness, o.EOP, o.CCCMS, o.Elderly, o.PhysDisabled, o.DevDisabled,
	   o.DSH, o.SSI, o.VRSS, e.Lifer, e.ReleaseCountyID, e.CustodyFacilityID, e.ScreeningDate, e.AuthToRepresent, e.ReleaseOfInfoSigned, e.EpisodeAcpDshTypeID, 
	   e.EpisodeMdoSvpTypeID, e.EpisodeMedReleaseTypeID, e.ReleasedToPRCS, e.CIDServiceRefusalDate, e.ReferralDate, e.ReleaseDate, e.Housing, e.ParoleUnit,
	   e.ParoleAgent, @BenefitWorkerID AS BenefitWorkerID,e.ScreeningDateSetByUserID,e._CIDServicePlanDate_Disabled,
	     e.FileDate, e.CalFreshRef, e.CalWorksRef,e.DHCSEligibility, e.DHCSEligibilityDate,e.DestinationID, o.MedPlacement,
	   (CASE WHEN ISNULL(@BenefitWorkerID, 0) > 0 THEN (SELECT (LastName + ',' + FirstName + ISNULL(MiddleName, '')) FROM dbo.[User] WHERE UserID  = @BenefitWorkerID) ELSE null END)BenefitWorkerName
FROM dbo.Episode e INNER JOIN dbo.Offender o ON e.OffenderID  = o.OffenderID AND e.EpisodeID  = @EpisodeID
SELECT EpisodeID, (CASE WHEN EpisodeID = @MEpisodeID THEN Convert(varchar,ReferralDate, 101) + '*' ELSE Convert(varchar,ReferralDate, 101) END)ReferralDate 
  FROM dbo.Episode WHERE OffenderID  = @OffenderID GROUP BY EpisodeID, ReferralDate  ORDER BY EpisodeID DESC
END
ELSE
BEGIN
 SELECT 0 AS EpisodeID, 0 AS OffenderID, ''CDCRNum, (CASE WHEN ISNULL(@SomsUploadID, 0) > 0 THEN 1 ELSE 0 END)SomsDataExists, 0 AS SomsFlagged, 
       0 AS CaseAssigned, ''LastName, ''FirstName, ''MiddleName, 0 AS PC290, 0 AS PC457, 0 AS USVet, 0 AS ReviewStatus,
	   0 AS SSN, null AS DOB, null AS GenderID,  0 AS LongTermMedCare, 0 AS Hospice, 0 AS AssistedLiving, 0 AS HIVPos, 0 AS ChronicIllness, 0 AS EOP, 0 AS CCCMS, 
	   0 AS Elderly, 0 AS PhysDisabled, 0 AS DevDisabled, 0 AS DSH, 0 AS SSI, 0 AS VRSS, 0 AS Lifer, null AS ReleaseCountyID, null AS CustodyFacilityID, 
	   null AS ScreeningDate, 0 AS AuthToRepresent, 0 AS ReleaseOfInfoSigned, null AS EpisodeAcpDshTypeID, null AS EpisodeMdoSvpTypeID, null AS EpisodeMedReleaseTypeID, 
	   null AS ReleasedToPRCS, null AS CIDServiceRefusalDate, null AS ReferralDate, null AS ReleaseDate, ''Housing,''ParoleUnit, ''ParoleAgent, null AS BenefitWorkerID,
	   null AS ScreeningDateSetByUserID,null AS _CIDServicePlanDate_Disabled, null AS DestinationID, 0 AS MedPlacement, null AS FileDate,null AS CalFreshRef, null AS CalWorksRef,
	   null AS DHCSEligibility, null AS DHCSEligibilityDate,null AS BenefitWorkerName
 SELECT 0 AS EPisodeID, ''ReferralDate
END
	   
SELECT CountyID, Name From dbo.County
SELECT FacilityID, (OrgCommonID + '-' + Name)NameWithCode, Abbr FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0 
SELECT GenderID, Code, Name FROM dbo.Gender WHERE ISNULL(Disabled, 0) = 0 
SELECT EpisodeAcpDshTypeID, Name FROM dbo.EpisodeAcpDshType 
SELECT EpisodeMdoSvpTypeID, Name FROM dbo.EpisodeMdoSvpType
SELECT EpisodeMedReleaseTypeID, Name FROM dbo.EpisodeMedReleaseType
SELECT lkValue, lkdescr_short  FROM dbo.LookUpTable WHERE ISNULL(Disabled, 0) = 0 
SELECT DISTINCT(CONVERT(varchar,ISNULL(ScheduledReleaseDate, ''), 101)) FROM dbo.SomsRecord WHERE CDCNumber = @CDCRNum

IF @All =  1
    EXEC [dbo].[spGetApplications] @EpisodeID, @CurrentUserID

END
GO

GRANT EXECUTE ON [dbo].[spGetInmateProfile] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
