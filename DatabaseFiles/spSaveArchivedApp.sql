USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spSaveArchivedApp]    Script Date: 11/6/2021 8:44:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spSaveArchivedApp]

CREATE PROCEDURE [dbo].[spSaveArchivedApp]
  @ApplicationID int,
  @EpisodeID int,
  @CurrentUserID int
 AS	
BEGIN
    DECLARE @AppTypeID int = (SELECT ApplicationTypeID FROM [dbo].[Application] 
	                           WHERE ApplicationID= @ApplicationID)

    IF EXISTS(SELECT 1 FROM [dbo].[Application] WHERE ApplicationTypeID = @AppTypeID AND EpisodeID = @EpisodeID AND ArchivedOnDate IS NOT NULL)
	BEGIN            
		DELETE FROM [dbo].[Application] WHERE ApplicationTypeID = @AppTypeID AND EpisodeID = @EpisodeID AND ArchivedOnDate IS NOT NULL
	END

    UPDATE  [dbo].[Application] SET ArchivedOnDate = GetDate(), [CreatedByUserID]= @CurrentUserID 
	 WHERE ApplicationID = @ApplicationID 
   
    INSERT INTO [dbo].[ApplicationTrace]
           ([ApplicationID],[ApplicationTypeID],[EpisodeID],[ApplicationOutcomeID]
           ,[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate],[OutcomeDate]
           ,[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID]
           ,[CustodyFacilityId],[DateAction])
     SELECT [ApplicationID],[ApplicationTypeID],[EpisodeID],[ApplicationOutcomeID]
           ,[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate],[OutcomeDate]
           ,[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID]
           ,[CustodyFacilityId],[DateAction] FROM [dbo].[Application]
	  WHERE ApplicationID = @ApplicationID

END
GO

GRANT EXECUTE ON [dbo].[spSaveArchivedApp] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO