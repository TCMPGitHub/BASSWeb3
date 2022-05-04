USE [BassWebTest]
GO

/****** Object:  StoredProcedure [dbo].[spGetArchivedApps]    Script Date: 8/10/2017 9:44:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Drop Procedure [spGetArchivedApps]
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGetArchivedApps]
	@EpisodeID int  = 0,
	@CurrentUserID int
AS
DECLARE @AppIDs TABLE(
  ApplicationID int,
  RowNum int
)
INSERT INTO @AppIDs
SELECT ApplicationID, ROW_NUMBER() OVER (PARTITION BY ApplicationTypeID ORDER BY ApplicationID DESC) AS RowNum 
  FROM Application 
 WHERE EpisodeID  = @EpisodeID AND ArchivedOnDate is not null

SELECT t1.ApplicationID, t1.ApplicationTypeID, t2.Name AS ApplicationTypeName, t1.AppliedOrRefusedOnDate, 
       t1.ArchivedOnDate,
  (CASE WHEN (((t1.CreatedByUserID = @CurrentUserID or t3.IsBenefitWorker = 1) OR t3.CanAccessReports =1) AND t4.RowNum = 1 ) THEN 1 ELSE 0 END)RestoreEnabled 
  FROM dbo.[Application] t1 INNER JOIN dbo.[ApplicationType] t2 ON t1.ApplicationTypeID = t2.ApplicationTypeID 
        INNER JOIN dbo.[User] t3 ON t1.CreatedByUserID = t3.UserID
        LEFT OUTER JOIN @AppIDs t4 on t1.ApplicationID = t4.ApplicationID
  WHERE episodeID  = @EpisodeID AND ArchivedOnDate IS NOT NULL
GO

GRANT EXECUTE ON [dbo].[spGetArchivedApps] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
