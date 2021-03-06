USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetApplicationByType]    Script Date: 11/7/2021 8:41:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetApplicationByType]

CREATE PROCEDURE [dbo].[spGetApplicationByType]
  @EpisodeID int,
  @CurrentUserID int,
  @ApplicationTypeID int
 AS	
BEGIN
   DECLARE @CanEditAllCases bit 
   DECLARE @CanAccessReports bit

	--Get user's permission settings
	SELECT @CanAccessReports = CanAccessReports, @CanEditAllCases = CanEditAllCases 
	  FROM [User] WHERE UserID  = @CurrentUserID

	 -- get all facilities
	 SELECT FacilityID, Abbr FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0

	 --Get Application Outcom list
	 SELECT [ApplicationOutcomeID] ,[Name], Position
       FROM [BassWebTest].[dbo].[ApplicationOutcome]
      WHERE ApplicationOutcomeID < 4 Order By Position

   --Get application by Application type
   IF EXISTS(SELECT 1 FROM [dbo].[Application]  
	          WHERE EpisodeID  = @EpisodeID AND ArchivedOnDate IS NULL AND ApplicationTypeID = @ApplicationTypeID )
	   SELECT [ApplicationID],[ApplicationTypeID],[EpisodeID],[ApplicationOutcomeID]
			  ,[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate]
			  ,[OutcomeDate],[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID]
			  ,[CustodyFacilityId],[DateAction],[DHCSDate], 
			  (CASE WHEN [CreatedByUserID] = @CurrentUserID OR 
			   (@CanEditAllCases = 1 OR  @CanAccessReports = 1)  THEN 1 ELSE 0 END)IsEditable
		  FROM [dbo].[Application]  
		 WHERE EpisodeID  = @EpisodeID AND ArchivedOnDate IS NULL AND ApplicationTypeID = @ApplicationTypeID
   ELSE
     SELECT 0 AS ApplicationID, @ApplicationTypeID AS ApplicationTypeID, @EpisodeID AS EpisodeID ,null AS [ApplicationOutcomeID]
			  , null AS [AgreesToApply], GetDate() AS [AppliedOrRefusedOnDate]
			  , null AS [PhoneInterviewDate]
			  , null AS [OutcomeDate],null AS [BICNum], null AS [IssuedOnDate]
			  , null AS [ArchivedOnDate], @CurrentUserID
			  , null AS [CustodyFacilityId],GetDate() AS DateAction,null AS [DHCSDate], 
			  1 AS IsEditable
End
GO
GRANT EXECUTE ON [dbo].[spGetApplicationByType] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 