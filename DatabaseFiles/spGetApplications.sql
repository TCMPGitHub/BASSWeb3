USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetApplications]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetApplications]

CREATE PROCEDURE [dbo].[spGetApplications]
  @EpisodeID int,
  @CurrentUserID int
 AS	
BEGIN
   DECLARE @CanEditAllCases bit 
   DECLARE @CanAccessReports bit
	DECLARE @ScreeningDate DateTime
	DECLARE @AuthToRepresent bit
	DECLARE @ReleaseOfInfoSigned bit
	DECLARE @IsVA bit = 0
	DECLARE @ButtonEnable bit = 0
	DECLARE @HasMediApp bit = 0
	DECLARE @HasSSIApp bit = 0
	DECLARE @HasVAApp bit = 0
	DECLARE @HasArchivedApps bit = 0

	--Get user's permission settings
	SELECT @CanAccessReports = CanAccessReports, @CanEditAllCases = CanEditAllCases 
	  FROM [User] WHERE UserID  = @CurrentUserID

	--find if application can be add/modified
	SELECT @ScreeningDate = ScreeningDate, @AuthToRepresent = AuthToRepresent,
	       @ReleaseOfInfoSigned = ReleaseOfInfoSigned, 
		   @IsVA = (CASE WHEN t2.VRSS = 1 OR t2.UsVet = 1 THEN 1 ELSE 0 END)
	  FROM EPisode t1 INNER JOIN Offender t2 ON t1.OffenderID  =  t2.OffenderID 
	 WHERE EpisodeID  =  @EpisodeID

	 IF @ScreeningDate IS NOT NULL AND @AuthToRepresent = 1 AND @ReleaseOfInfoSigned = 1 
	   SET @ButtonEnable = 1
      
	 --make sure existed application expired, then archived it
	 DECLARE @AppliedOrRefusedOnDate DateTime 
	 DECLARE @CreatedByUserID int
	 DECLARE @ApplicationID int

	 IF EXISTS(SELECT 1 FROM  [dbo].[Application] WHERE ApplicationTypeID = 0 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID)
	 BEGIN	   
		SELECT @ApplicationID =ApplicationID, @AppliedOrRefusedOnDate = AppliedOrRefusedOnDate, @CreatedByUserID = CreatedByUserID FROM [dbo].[Application] WHERE ApplicationTypeID = 0 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID
		IF DateDiff(month, @AppliedOrRefusedOnDate,  GetDate()) > 12 AND @CreatedByUserID <> @CurrentUserID 
	    BEGIN
		   EXEC [dbo].[spSaveArchivedApp]  @ApplicationID,@EpisodeID,@CurrentUserID
        END
		ELSE
		  SET @HasSSIApp = 1
	  END

	 IF EXISTS(SELECT 1 FROM  [dbo].[Application] WHERE ApplicationTypeID = 1 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID)
	 BEGIN	   
		SELECT @ApplicationID =ApplicationID, @AppliedOrRefusedOnDate = AppliedOrRefusedOnDate, @CreatedByUserID = CreatedByUserID FROM  [dbo].[Application] WHERE ApplicationTypeID = 1 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID
		IF DateDiff(month, @AppliedOrRefusedOnDate,  GetDate()) > 12 AND @CreatedByUserID <> @CurrentUserID 
	    BEGIN
	        EXEC [dbo].[spSaveArchivedApp] @ApplicationID, @EpisodeID,  @CurrentUserID
        END
		ELSE
	      SET @HasVAApp = 1 
      END

	IF EXISTS(SELECT 1 FROM  [dbo].[Application] WHERE ApplicationTypeID = 2 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID)
	BEGIN	   
		SELECT @ApplicationID =ApplicationID, @AppliedOrRefusedOnDate = AppliedOrRefusedOnDate, @CreatedByUserID = CreatedByUserID FROM  [dbo].[Application] WHERE ApplicationTypeID = 2 AND ArchivedOnDate IS NULL AND EpisodeID  = @EpisodeID
		IF DateDiff(month, @AppliedOrRefusedOnDate,  GetDate()) > 12 AND @CreatedByUserID <> @CurrentUserID 
	    BEGIN
	        EXEC [dbo].[spSaveArchivedApp]  @ApplicationID, @EpisodeID,  @CurrentUserID
        END
		ELSE
	      SET @HasMediApp = 1 
     END

	IF EXISTS(SELECT 1 FROM  [dbo].[Application] WHERE ArchivedOnDate IS NOT NULL AND EpisodeID  = @EpisodeID) AND @ButtonEnable =1
	    SET @HasArchivedApps = 1 
	--Get all flags
	SELECT @EpisodeID As EpisodeID, @HasMediApp AS HasMediCalApp, @HasSSIApp AS HasSSIApp, 
	       @HasVAApp AS HasVAApp,@HasArchivedApps AS HasArchivedApps,
	       @ButtonEnable AS ButtonEnable, @IsVA AS IsVAInmate

   --Get all applications
   --SELECT [ApplicationID],[ApplicationTypeID],[EpisodeID],[ApplicationOutcomeID]
   --       ,[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate]
   --       ,[OutcomeDate],[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID]
   --       ,[CustodyFacilityId],[DateAction],[DHCSDate], 
		 -- (CASE WHEN [CreatedByUserID] = @CurrentUserID OR 
		 --  (@CanEditAllCases = 1 OR  @CanAccessReports = 1)  THEN 1 ELSE 0 END)IsEditable
   --   FROM [dbo].[Application] t1 WHERE EpisodeID  = @EpisodeID AND ArchivedOnDate IS NULL
End
GO

GRANT EXECUTE ON [dbo].[spGetApplications] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

