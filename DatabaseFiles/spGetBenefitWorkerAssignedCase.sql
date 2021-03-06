USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetBenefitWorkerAssignedCase]    Script Date: 11/6/2021 8:52:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop PROCEDURE [dbo].[spGetBenefitWorkerAssignedCase]

CREATE PROCEDURE [dbo].[spGetBenefitWorkerAssignedCase]
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
	from (select EpisodeID, BenefitWorkerID from CaseAssignment WHERE BenefitWorkerID = @BenefitWorkerId AND UnAssignedDateTime is null) C inner join  
	
	(SELECT E.CDCRNum, E.EpisodeID, (O.LastName + ', ' +  O.FirstName  + ' ' + ISNULL(O.MiddleName, '')) AS ClientName, E.Housing,
	        F.OrgCommonID as CustFacilityName, S.SomsCustFacilityName, S.Codes, S.MHClass, S.SomsReleaseDate, E.ReleaseDate
	   FROM Episode E INNER JOIN Offender O on E.OffenderID  =  O.OffenderID
	        LEFT OUTER JOIN   Facility F ON E.CustodyFacilityID = F.FacilityID
			LEFT OUTER JOIN 
			 (Select ScheduledReleaseDate AS SomsReleaseDate, Unit AS SomsCustFacilityName, 
	              CDCNumber, 
				  (CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 'EOP' 
	                    WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 'CCCMS' 
	                ELSE '' END) AS MHClass, 
                  (ISNULL(DevelopDisabledEvaluation, '') + ' ' + ISNULL(DPPHearingCode, '') + ' ' + 
				   ISNULL(DPPVisionCode, '') + ' '  + ISNULL(DPPMobilityCode, '' ) + ' ' + 
				   ISNULL(DPPSpeechCode, '')) AS Codes
	        FROM SomsRecord WHERE SomsUploadID = @MaxSomsUploadID and ScheduledReleaseDate is not null) AS S
			ON E.CDCRNum = S.CDCNumber WHERE ISNULL(E.ReleaseDate, E.SomsReleaseDate) > DateAdd(D, -7, GetDate())) T ON C.EpisodeID  =  T.EpisodeID
			order by T.CDCRNum
 --  SELECT C.EpisodeID, t1.CDCRNum, t1.ClientName, (t1.MHClass + ' ' + t1.Codes)MHClass, t1.SomsReleaseDate, t1.ReleaseDate, t1.SomsCustFacilityName, 
 --        t1.CustFacilityName, t1.Housing,(select dbo.fnGetApplicationTypeName(t1.EpisodeID)) as Apps,
	--	 (select dbo.fnGetDispositionDesc(t1.EpisodeID)) as AppStatus, 
	--	 (select dbo.fnGetRedFlag(t1.EpisodeID))RedFlag
	--from CaseAssignment C inner join    
 --    ( SELECT e.CDCRNum, e.EpisodeID, f.OrgCommonID AS CustFacilityName, ISNULL(e.ReleaseDate, e.SomsReleaseDate) AS ReleaseDate, S.SomsReleaseDate,
 --           S.SomsCustFacilityName, S.Codes, S.MHClass,
 --         (o.LastName + ', ' +  o.FirstName  + ' ' + ISNULL(o.MiddleName, '')) AS ClientName, e.Housing 
 --        FROM Episode e inner join Offender o on e.OffenderID = o.OffenderID inner join Facility f 
	--       on e.CustodyFacilityID = f.FacilityID  LEFT OUTER JOIN 
	--     (Select ScheduledReleaseDate AS SomsReleaseDate, Unit AS SomsCustFacilityName, 
	--              CDCNumber, 
	--			  (CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 'EOP' 
	--                    WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 'CCCMS' 
	--                ELSE '' END) AS MHClass, 
 --                 (ISNULL(DevelopDisabledEvaluation, '') + ' ' + ISNULL(DPPHearingCode, '') + ' ' + 
	--			   ISNULL(DPPVisionCode, '') + ' '  + ISNULL(DPPMobilityCode, '' ) + ' ' + 
	--			   ISNULL(DPPSpeechCode, '')) AS Codes
	--        FROM SomsRecord WHERE SomsUploadID = @MaxSomsUploadID and ScheduledReleaseDate is not null) AS S 
	--	       ON e.CDCRNum = S.CDCNumber ) AS t1 
	--  ON C.EpisodeID = t1.EpisodeID 
 --  WHERE c.BenefitWorkerID = @BenefitWorkerId AND c.UnAssignedDateTime is null and 
	--     ISNULL(t1.ReleaseDate, t1.SomsReleaseDate) > DateAdd(D, -7, GetDate()) order by t1.CDCRNum
  
END
GO

GRANT EXECUTE ON [dbo].[spGetBenefitWorkerAssignedCase] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 


