USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetSearchingList]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetSearchingList]

CREATE PROCEDURE [dbo].[spGetSearchingList]
  @CurrentUserID int
 AS	
BEGIN
    SELECT UserID, (LastName + ', ' + FirstName + ISNULl(MiddleName, ''))UserLFM FROM dbo.[User] WHERE IsActive = 1 ORDER BY UserLFM
	SELECT FacilityID, (Abbr + '-' + Name)NameWithCode FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0
	SELECT CaseNoteTypeID, Name FROM CaseNoteType WHERE ISNULL(Disabled, 0) = 0

	IF exists(SELECT IsBenefitWorker, SupervisorID  FROM dbo.[User] WHERE UserID = @CurrentUserID AND IsActive = 1 AND IsBenefitWorker = 1 AND SupervisorID <> UserID)
	BEGIN
	  IF EXISTS(SELECT 1 FROM CaseAssignment WHERE BenefitWorkerID = @CurrentUserID AND UnAssignedDateTime IS NULL)
	      SELECT EpisodeID, CDCRNum FROM dbo.Episode WHERE EpisodeID = ISNULL
	         ((SELECT Top 1 EpisodeID FROM CaseAssignment WHERE BenefitWorkerID = @CurrentUserID AND UnAssignedDateTime IS NULL order by EpisodeID Desc), 0)
	  ELSE 
	    SELECT 0 AS EpisodeID, '' CDCRNum 
	END
	ELSE
	  SELECT 0 AS EpisodeID, '' CDCRNum 

END

GO

GRANT EXECUTE ON [dbo].[spGetSearchingList] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

