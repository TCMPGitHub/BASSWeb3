USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetUserAndTeamAppsWorked]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[spGetUserAndTeamAppsWorked]
CREATE PROCEDURE [dbo].[spGetUserAndTeamAppsWorked]
  @UserID int,
  @StartDate DateTime,
  @EndDate DateTime
 AS	
BEGIN
 --DECLARE @UserID  int = 1018
 --DECLARE @StartDate DateTime = '2017-01-01'
 --DECLARE @EndDate DateTime = '2017-03-01'
 IF EXISTS(SELECT AssignedDateTime, AssignedDateTime FROM dbo.CaseAssignment
            WHERE LatestAssignment = 1 AND AssignedDateTime >= @StartDate AND AssignedDateTime <= @EndDate AND BenefitWorkerID = @UserID )
 BEGIN
	 SELECT [Date],SUM([Current])[Current], SUM([Target])[Target] FROM
	(SELECT FORMAT(Convert(DateTime, AssignedDateTime), 'dd-MMM-yy')[Date], COUNT(AssignedDateTime) AS [Current], 0 AS [Target] FROM dbo.CaseAssignment
	 WHERE LatestAssignment = 1 AND AssignedDateTime >= @StartDate AND AssignedDateTime <= @EndDate AND BenefitWorkerID = @UserID 
	 GROUP BY FORMAT(Convert(DateTime,AssignedDateTime), 'dd-MMM-yy')
	 union
	 SELECT FORMAT(Convert(DateTime, AssignedDateTime), 'dd-MMM-yy')[Date], 0 AS [Current],  
		COUNT( UnAssignedDateTime)[Target] FROM dbo.CaseAssignment
	 WHERE LatestAssignment = 1 AND AssignedDateTime >= @StartDate AND AssignedDateTime <= @EndDate AND BenefitWorkerID = @UserID AND UnAssignedDateTime IS NOT NULL
	 GROUP BY FORMAT(Convert(DateTime,AssignedDateTime), 'dd-MMM-yy'))T GROUP BY [Date]
End
ELSE
  SELECT GetDate() AS [Date], 0 AS [Current], 0 As [Target]

END
GO

GRANT EXECUTE ON [dbo].[spGetUserAndTeamAppsWorked] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

