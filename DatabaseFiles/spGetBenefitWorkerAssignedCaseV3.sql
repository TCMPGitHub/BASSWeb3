USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetBenefitWorkerAssignedCase]    Script Date: 11/9/2021 4:15:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop PROCEDURE [dbo].[spGetBenefitWorkerAssignedCaseV3]

CREATE PROCEDURE [dbo].[spGetBenefitWorkerAssignedCaseV3]
    @BenefitWorkerId int = 0
AS
BEGIN
  
  DECLARE @MaxSomsUploadID int = (SELECT MAX(SomsUploadID) FROM SomsUpload)

  --if @BenefitWorkerId = 0
  --  SET @BenefitWorkerId = 1003
  
  -- auto unassign for the selected benefitworker
  Update CaseAssignment SET UnAssignedDateTime = GetDate()  where EpisodeID in (
  select D.EpisodeID from CaseAssignment C inner join 
   ( SELECT e.EpisodeID,e.CDCRNum, e.ReleaseDate
      FROM Episode e inner join Offender o on e.OffenderID = o.OffenderID inner join Facility f 
	  on e.CustodyFacilityID = f.FacilityID ) AS D on C.EpisodeID = D.EpisodeID  LEFT OUTER JOIN 
	  (Select ScheduledReleaseDate AS SomsReleaseDate, CDCNumber
	   from SomsRecord where SomsUploadID = @MaxSomsUploadID) AS S on D.CDCRNum = s.CDCNumber  
	  WHERE c.BenefitWorkerID = @BenefitWorkerId and C.UnAssignedDateTime is null and 
	  (D.ReleaseDate < DateAdd(day, -1, GetDate()) ))   

  --get all assign cases
  SELECT C.EpisodeID, T.CDCRNum, T.ClientName, (T.MHClass + ' ' + T.Codes)MHClass, T.SomsReleaseDate, T.ReleaseDate, T.SomsCustFacilityName, 
         T.CustFacilityName, T.Housing,(select dbo.fnGetApplicationTypeName(T.EpisodeID)) as Apps,
		 (select dbo.fnGetDispositionDesc(T.EpisodeID)) as AppStatus, 
		 (select dbo.fnGetRedFlag(T.EpisodeID))RedFlag
	from (select EpisodeID, BenefitWorkerID from CaseAssignment WHERE BenefitWorkerID = @BenefitWorkerId AND UnAssignedDateTime is null AND LatestAssignment = 1) C inner join  
	
	(SELECT E.CDCRNum, E.EpisodeID, (O.LastName + ', ' +  O.FirstName  + ' ' + ISNULL(O.MiddleName, '')) AS ClientName, E.Housing,E.ReleaseDate,
	        F.OrgCommonID as CustFacilityName, S.SomsCustFacilityName, S.Codes, S.MHClass, S.SomsReleaseDate 
	   FROM (Select EpisodeID, OffenderID, CDCRNum, Housing, ReleaseDate, CustodyFacilityID,SomsReleaseDate, SomsUploadID  from Episode WHERE LatestEpisode = 1) E INNER JOIN Offender O on E.OffenderID  =  O.OffenderID
	        LEFT OUTER JOIN Facility F ON E.CustodyFacilityID = F.FacilityID
			LEFT OUTER JOIN 
			 (Select ScheduledReleaseDate AS SomsReleaseDate, Unit AS SomsCustFacilityName, CDCNumber, SomsUploadID,
				  (CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 'EOP' 
	                    WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 'CCCMS' ELSE '' END) AS MHClass, 
                  (ISNULL(DevelopDisabledEvaluation, '') + ' ' + ISNULL(DPPHearingCode, '') + ' ' + 
				   ISNULL(DPPVisionCode, '') + ' '  + ISNULL(DPPMobilityCode, '' ) + ' ' +  ISNULL(DPPSpeechCode, '')) AS Codes
	        FROM SomsRecord )S ON E.CDCRNum = S.CDCNumber AND s.SomsUploadID = e.SomsUploadID 
			WHERE ISNULL(E.ReleaseDate, E.SomsReleaseDate) > DateAdd(D, -37, GetDate())) T ON C.EpisodeID  =  T.EpisodeID			
			order by T.CDCRNum
  
END
GO

GRANT EXECUTE ON [dbo].[spGetBenefitWorkerAssignedCaseV3] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 


