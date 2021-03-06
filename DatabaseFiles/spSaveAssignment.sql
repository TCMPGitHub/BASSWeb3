USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetSearchingList]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spSaveAssignment]

CREATE PROCEDURE [dbo].[spSaveAssignment]
  @EpisodeID int,
  @BenefitWorkerID int,
  @CurrentUserID int
 AS	
BEGIN
    UPDATE  [dbo].[CaseAssignment] SET UnAssignedDateTime = GetDate() WHERE EpisodeID = @EpisodeID AND UnAssignedDateTime IS NULL
   -- DECLARE @counts int =(SELECT COUNT(*) FROM  [dbo].[CaseAssignment] WHERE EpisodeID = @EpisodeID AND UnAssignedDateTime IS NULL)
    IF @BenefitWorkerID > 0
	BEGIN
	   IF Exists(SELECT 1 FROM dbo.CaseAssignment WHERE EpisodeID  = @EpisodeID)
         UPDATE dbo.CaseAssignment SET LatestAssignment = null WJERE EpisodeID  = @EpisodeID
         INSERT INTO [dbo].[CaseAssignment]([EpisodeID],[BenefitWorkerID],[AssignedDateTime],[ActionBy], LatestAssignment)
            VALUES ( @EpisodeID ,@BenefitWorkerID,GetDate(), @CurrentUserID, 1)
    END
	exec [dbo].[spGetInmateProfile] @EpisodeID, @CurrentUserID, 1
END

GO

GRANT EXECUTE ON [dbo].[spSaveAssignment] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

