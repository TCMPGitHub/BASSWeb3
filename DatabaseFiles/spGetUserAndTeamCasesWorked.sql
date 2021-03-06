USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetUserAndTeamCasesWorked]    Script Date: 11/7/2021 6:14:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[spGetUserAndTeamCasesWorked]
CREATE PROCEDURE [dbo].[spGetUserAndTeamCasesWorked]
  @UserID int,
  @StartDate DateTime,
  @EndDate DateTime
 AS	
BEGIN
   --DECLARE @UserID  int = 1018
   --DECLARE @StartDate DateTime = '2017-01-01'
   --DECLARE @EndDate DateTime = '2017-03-01'
   DECLARE @SupervisorID int = (SELECT SupervisorID FROM dbo.[User] WHERE UserID = @UserID)
   DECLARE @UserTeamWorked Table(
     CreatedDateTime DateTime,
	 EpisodeID int,
	 UserID int
 )

 IF ISNULL(@SupervisorID, 0) <> 0
  BEGIN 
    --get all team's work
    INSERT INTO @UserTeamWorked
    SELECT CreatedDateTime,EpisodeID, UserID FROM 
      (SELECT CreatedDateTime,CaseNoteID,casenotetraceID, UserID,EpisodeID, ActionStatus, ROW_NUMBER() OVER (PARTITION BY CaseNoteTraceID ORDER BY CaseNoteID DESC) AS RowNum 
	     FROM dbo.CaseNote WHERE ActionStatus <> 10 AND CreatedDateTime >= @StartDate AND CreatedDateTime <= @EndDate)T 
	    WHERE T.RowNum =  1 AND T.UserID in  (SELECT UserID FROM dbo.[User] WHERE SupervisorID = @SupervisorID)
  END 
  IF EXISTS(SELECT 1 FROM @UserTeamWorked)
   BEGIN
     SELECT t1.CNDate AS [Date], t2.UserTotalCasesWorked, t1.TeamTotalCasesWorked FROM
      (select CONVERT(date, CreatedDateTime)CNDate, COUNT(distinct EpisodeID)TeamTotalCasesWorked from @UserTeamWorked GROUP BY CONVERT(date, CreatedDateTime))t1 LEFT OUTER JOIN 
      (Select CONVERT(date, CreatedDateTime)CNDate, COUNT(distinct EpisodeID)UserTotalCasesWorked from @UserTeamWorked WHERE UserID  = @UserID GROUP BY CONVERT(date, CreatedDateTime))t2 
   ON t1.CNDate = t2.CNDate 
   END
 ELSE
   SELECT GetDate() AS [Date], 0 AS UserTotalCasesWorked, 0 AS TeamTotalCasesWorked
 END
 GO

 GRANT EXECUTE ON [dbo].[spGetUserAndTeamCasesWorked] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
 GO