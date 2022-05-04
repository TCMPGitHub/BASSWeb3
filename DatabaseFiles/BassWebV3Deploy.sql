USE [BassWebTest]
GO
/*================================================================
Create EpisodeOffender table for Episode Offender data changes
==================================================================*/
IF EXISTS(SELECT 1 FROM sys.Tables WHERE  Name = N'EpisodeOffender' AND Type = N'U')
  DROP TABLE dbo.EpisodeOffender

CREATE TABLE dbo.EpisodeOffender(
    EpisodeID int primary key not null, 
	MiddleName nvarchar(50) null, 
	PC290 bit not null, 
	PC457 bit not null, 
	USVet bit not null,
	SSN nvarchar(11) not null, 
	DOB datetime null,
	GenderID int not null, 
	LongTermMedCare bit not null, 	
	Hospice bit not null, 
	AssistedLiving bit not null, 
	HIVPos bit not null,
	ChronicIllness bit not null, 
	EOP bit not null, 
	PhysDisabled bit not null, 
	DevDisabled bit not null, 
    CCCMS bit not null, 
	Elderly bit not null, 
	DSH bit not null, 	
	ReleaseCountyID int null,
	ScreeningDate datetime null,
	AuthToRepresent int not null, 
	ReleaseOfInfoSigned int not null, 
	ReleasedToPRCS int null,
	CIDServiceRefusalDate datetime null, 
	ReleaseDate DateTime null, 
    Housing nvarchar(25) not null,	
	CustodyFacilityID int null,
	Lifer bit not null, 
	ScreeningDateSetByUserID int null, 
	DestinationID int null,
  	CalFreshRef int null, 
	CalWorksRef int null, 
	ActionBy int not null,
	DateAction datetime not null
)
GO
/*================================================================
  Create ApplicationTrace table for Episode Offender data changes
==================================================================*/
IF EXISTS(SELECT 1 FROM sys.Tables WHERE  Name = N'ApplicationTrace' AND Type = N'U')
  DROP TABLE dbo.ApplicationTrace
CREATE TABLE [dbo].[ApplicationTrace](
	[ApplicationTraceID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[ApplicationTypeID] [int] NOT NULL,
	[EpisodeID] [int] NOT NULL,
	[ApplicationOutcomeID] [int] NULL,
	[AgreesToApply] [bit] NULL,
	[AppliedOrRefusedOnDate] [datetime] NOT NULL,
	[PhoneInterviewDate] [datetime] NULL,
	[OutcomeDate] [datetime] NULL,
	[BICNum] [nvarchar](20) NULL,
	[IssuedOnDate] [datetime] NULL,
	[ArchivedOnDate] [datetime] NULL,
	[CreatedByUserID] [int] NULL,
	[CustodyFacilityId] [int] NULL,
	[DateAction] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo.ApplicationTrace] PRIMARY KEY CLUSTERED 
(
	[ApplicationTraceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/*================================================================
 Add new column of Episode
==================================================================*/
IF COL_LENGTH('Episode','LatestEpisode') IS NULL
BEGIN
  ALTER TABLE Episode
  ADD LatestEpisode bit null
END
GO

/*================================================================
 Add new column of CaseAssignment
==================================================================*/
IF COL_LENGTH('CaseAssignment','LatestAssignment') IS NULL
BEGIN
   ALTER TABLE CaseAssignment
   ADD LatestAssignment bit null
END
GO
/* ==============================================================
  Create procedure sp_GetAllApplications 
=================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[sp_GetAllApplications]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[sp_GetAllApplications]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetAllApplications] 
  @EpisodeID int = 0,
  @ApplicationTypeID int = -1,
  @CountyID int = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @StatusA int = 0
    DECLARE @StatusB int = 0
  
    IF @ApplicationTypeID > -1
     BEGIN
       SET @StatusB = 1
       SET @StatusA = 0
     END
    ELSE
     BEGIN
       SET @StatusB = 0
       SET @StatusA = 1
     END
	 IF @CountyID > -1
	 BEGIN
	 SELECT ApplicationID, ApplicationTypeID, t1.EpisodeID, t2.CDCRNum,t2.ClientName, 
	       (Select Name From dbo.County Where CountyID = ISNULl(t2.ReleaseCountyID, 0))ReleaseCountyName, 
	       (CASE WHEN t2.EOP = 1 THEN 'EOP' WHEN t2.CCCMS = 1 THEN 'CCCMS' ELSE '' END)MHStatus,
	       AgreesToApply, AppliedOrRefusedOnDate,
		   (CASE WHEN PhoneInterviewDate = null THEN '' ELSE Convert(varchar(10), PhoneInterviewDate, 101) END)PhoneInterviewDate,
		   (CASE WHEN OutcomeDate = null THEN '' ELSE Convert(varchar(10), OutcomeDate, 101) END)OutcomeDate,
		   (CASE WHEN ISNULL(ApplicationOutcomeID, -1) < 0 AND AgreesToApply = 0 AND AppliedOrRefusedOnDate IS NOT NULL THEN 'Refused' 
		   WHEN ISNULL(ApplicationOutcomeID, -1) < 0 AND AgreesToApply = 1 THEN 'Pending' ELSE (SELECT NAME FROM ApplicationOutCome WHERE ApplicationOutcomeID = t1.ApplicationOutcomeID)  END )OutCome,
		   (SELECT Name FROM ApplicationType WHERE ApplicationTypeID  = t1.ApplicationTypeID)ApplicationTypeName,
		   (CASE WHEN ArchivedOnDate = null THEN '' ELSE Convert(varchar(10), ArchivedOnDate, 101) END)ArchivedOnDate, BICNum,
		   (CASE WHEN IssuedOnDate = null THEN '' ELSE Convert(varchar(10), IssuedOnDate, 101) END)IssuedOnDate   
	  From Application t1 INNER JOIN (SELECT e.EpisodeID, e.CDCRNum, o.EOP, o.CCCMS, e.ReleaseCountyID,
	   (o.LastName + ',' + o.FirstName + ' ' + ISNULl(o.MiddleName, ''))ClientName
	   FROM Episode e inner join Offender o on e.OffenderID  = o.OffenderID Where e.ReleaseCountyID  = @CountyID) t2 on t1.EpisodeID  = t2.EpisodeID order by AppliedOrRefusedOnDate DESC,EpisodeID ASC
	 END
	 ELSE
	 BEGIN
  SELECT ApplicationID, ApplicationTypeID, t1.EpisodeID, t2.CDCRNum,t2.ClientName, 
	       (Select Name From dbo.County Where CountyID = ISNULl(t2.ReleaseCountyID, 0))ReleaseCountyName,
	       (CASE WHEN t2.EOP = 1 THEN 'EOP' WHEN t2.CCCMS = 1 THEN 'CCCMS' ELSE '' END)MHStatus,
	       AgreesToApply, AppliedOrRefusedOnDate,
		   (CASE WHEN PhoneInterviewDate = null THEN '' ELSE Convert(varchar(10), PhoneInterviewDate, 101) END)PhoneInterviewDate,
		   (CASE WHEN OutcomeDate = null THEN '' ELSE Convert(varchar(10), OutcomeDate, 101) END)OutcomeDate,
		   (CASE WHEN ISNULL(ApplicationOutcomeID, -1) < 0 AND AgreesToApply = 0 AND AppliedOrRefusedOnDate IS NOT NULL THEN 'Refused' 
		   WHEN ISNULL(ApplicationOutcomeID, -1) < 0 AND AgreesToApply = 1 THEN 'Pending' ELSE (SELECT NAME FROM ApplicationOutCome WHERE ApplicationOutcomeID = t1.ApplicationOutcomeID)  END )OutCome,
		   (SELECT Name FROM ApplicationType WHERE ApplicationTypeID  = t1.ApplicationTypeID)ApplicationTypeName,
		   (CASE WHEN ArchivedOnDate = null THEN '' ELSE Convert(varchar(10), ArchivedOnDate, 101) END)ArchivedOnDate, BICNum,
		   (CASE WHEN IssuedOnDate = null THEN '' ELSE Convert(varchar(10), IssuedOnDate, 101) END)IssuedOnDate   
	  From Application t1 INNER JOIN (SELECT e.EpisodeID, o.EOP, o.CCCMS, e.CDCRNum, e.ReleaseCountyID,
	   (o.LastName + ',' + o.FirstName + ' ' + ISNULl(o.MiddleName, ''))ClientName FROM Episode e inner join Offender o on e.OffenderID  = o.OffenderID where e.EpisodeID  = @EpisodeID) t2 on t1.EpisodeID  = t2.EpisodeID 	
	 WHERE AppliedOrRefusedOnDate >= DateAdd(Year, -1, GetDate()) AND (1 =@StatusA AND t1.EpisodeID = @EpisodeID) OR (1=@StatusB AND t1.EpisodeID = @EpisodeID AND t1.ApplicationTypeID = @ApplicationTypeID)
	END
END
GO
GRANT EXECUTE ON [dbo].[sp_GetAllApplications] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
/*================================================================
   Create procedure spGetApplicationEpisodesDropdownList 
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetApplicationEpisodesDropdownList]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetApplicationEpisodesDropdownList]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetApplicationEpisodesDropdownList]
      @SearchString nvarchar(120) ='',
	  @EpisodeID int  = 0
	AS
BEGIN
	SET NOCOUNT ON

	IF @EpisodeID > 0
	BEGIN
	  DECLARE @OffenderID int = (SELECT OffenderID FROM Episode Where EpisodeID = @EpisodeID)
	   SELECT CONVERT(VARCHAR(10), EpisodeID) as Value,  CONCAT((CASE WHEN ReleaseDate IS NULL THEN '     NA' ELSE (SPACE(7-len(CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(),ReleaseDate)))) + CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(), ReleaseDate))) END), ' - ',  CDCRNum, (CASE WHEN LatestEpisode =1 THEN '*' ELSE ''END))[Text] 
 FROM Episode 
 WHERE OffenderID = @OffenderID Order By EpisodeID Desc
	END
	ELSE
	BEGIN
--DECLARE @HasCDCRORLT int = (CASE WHEN @searchString <> '' THEN 1 ELSE 0 END)
SELECT TOP 1000  CONVERT(VARCHAR(10), EpisodeID) as Value, 
 CONCAT((CASE WHEN ReleaseDate IS NULL THEN '     NA' ELSE (SPACE(7-len(CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(),ReleaseDate)))) + CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(), ReleaseDate))) END), ' - ', CONVERT(VARCHAR(12), PID),' - ', CDCRNum, ' - ', ClientName)[Text] 
  FROM 
  (SELECT EpisodeID, ReLeaseDate, CDCRNum, PID, (LastName + ', ' + FirstName + ' ' + ISNULl(MiddleName, ''))ClientName FROM Episode e
  INNER JOIN OFFENDER o ON e.offenderID  =  o.OffenderID
 WHERE LatestEpisode = 1 AND e.CDCRNum like '%' + @searchString + '%' OR o.LastName like '%' + @searchString + '%'
  AND ISNULL(e.ReLeaseDate, e.ReferralDate) > DateAdd(Year, -3, GetDate()))T
 Order by Text
 END
	
END
GO
GRANT EXECUTE ON [dbo].[spGetApplicationEpisodesDropdownList] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
/*================================================================
   Create procedure spCaseAssignmentsV3 
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spCaseAssignmentsV3]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spCaseAssignmentsV3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCaseAssignmentsV3]
	-- Add the parameters for the stored procedure here
	@FromDate DateTime = NULL,
	@ToDate DateTime = NULL,
	@Facility int = 0,
	@MaybeCDCR nvarchar(100)='',
	@Lifer bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from.
	SET NOCOUNT ON;

   --DECLARE  @FromDate DateTime= '2018-01-01'
   --DECLARE  @ToDate DateTime = null
   IF @FromDate IS NULL 
	   SET @FromDate = GetDate()

	IF @ToDate is NULL 
	  SET @ToDate = DateAdd(DAY, 180, @FromDate)

	DECLARE @HasFa bit = (CASE WHEN @Facility > 0 THEN 1 ELSE 0 END)
	DECLARE @HasCDCR bit = (CASE WHEN @MaybeCDCR <> '' THEN 1 ELSE 0 END)
	--DECLARE @Hasqualifier bit = (CASE WHEN @qualifier > 0 THEN 1 ELSE 0 END)

	DECLARE @tempETable Table (
      EpisodeID int NOT NULL primary key
    )
	INSERT INTO @tempETable 
   SELECT EpisodeID From Episode e INNER JOIN Offender o on e.OffenderID  =  o.OffenderID WHERE 
   ((ISNULL(ReleaseDate, SomsReleaseDate) IS NOT NULL AND ISNULL(ReleaseDate, SomsReleaseDate) >= @FromDate AND ISNULL(ReleaseDate, SomsReleaseDate) <= @ToDate) OR
   (ISNULL(ReleaseDate, SomsReleaseDate) IS NULL AND ReferralDate >= @FromDate AND ReferralDate <= @ToDate)) AND LatestEpisode = 1 AND 
   (( @HasFa =1 AND CustodyFacilityID = @Facility) OR (@HasFa = 0 AND 1=1)) AND 
   (( @HasCDCR =1 AND CustodyFacilityID = @Facility) OR (@HasCDCR = 0 AND 1=1)) AND
   (( @HasCDCR = 1 AND CDCRNum like '%' + @MaybeCDCR + '%' OR o.LastName like '%' + @MaybeCDCR + '%') OR( @HasCDCR = 0 AND 1=1)) AND
   (( @lifer = 1 AND Lifer = 1) OR (@lifer = 0 AND 1 = 1))

 SELECT e.EpisodeID, e.ReleaseDate, (o.LastName + ', ' + o.FirstName + ' ' + ISNULL(o.MiddleName, '')) AS OffenderName,
	 c.CaseAssignmentID, c.BenefitWorkerID, (CASE WHEN o.USVet = 1 THEN 1 
	                                              WHEN o.Elderly = 1 THEN 2
												  WHEN o.CCCMS = 1 THEN 3 
												  WHEN o.DevDisabled = 1 THEN 4
												  WHEN o.PhysDisabled = 1 THEN 5
												  WHEN o.EOP = 1 THEN 6
												  WHEN o.DSH = 1 THEN 7
												  WHEN o.ChronicIllness = 1 THEN 8
												  WHEN o.HIVPos = 1 THEN 9
												  WHEN o.AssistedLiving = 1 THEN 10
												  WHEN o.Hospice = 1 THEN 11
												  WHEN o.LongTermMedCare = 1 THEN 12 ELSE 0 END ) AS HighestCasePriority,
	 (CASE WHEN (ISNULL(c.BenefitWorkerID, '') = '' OR  UnAssignedDateTime IS NOT NULL)  THEN '' ELSE (SELECT Name FROM [dbo].[fn_GetUserName](c.BenefitWorkerID)) END)BenefitWorkerName,
	 (CASE WHEN e.CustodyFacilityID IS NULL THEN '' ELSE (Select top 1 OrgCommonID  From Facility WHERE FacilityID = e.CustodyFacilityID) END)FacilityName,
     e.CustodyFacilityID, e.CDCRNum, e.Housing, o.CCCMS, o.DSH, o.USVet, o.EOP, o.ChronicIllness, o.DevDisabled, o.Elderly, o.LongTermMedCare, 
	 o.HIVPos, o.AssistedLiving, o.PhysDisabled, o.Hospice, e.Lifer
	 FROM Episode e INNER JOIN @tempETable e1 ON e.EpisodeID  = e1.EpisodeID
	                INNER JOIN Offender o ON   e.OffenderID  =  o.OffenderID 
		            Left OUTER JOIN  (SELECT CaseAssignmentID, EpisodeID, BenefitWorkerID, UnAssignedDateTime 
					                    FROM CaseAssignment WHERE LatestAssignment = 1) c ON e.EpisodeID = c.EpisodeID 

	
END

--and e.ReleaseDate < DateAdd(day, 180,@FromDate)
GO
GRANT EXECUTE ON [dbo].[spCaseAssignmentsV3] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
/*================================================================
   Create procedure spSaveArchivedApp
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spSaveArchivedApp]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spSaveArchivedApp]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
/*================================================================
   Create procedure spSaveAssignment
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spSaveAssignment]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spSaveAssignment]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
         UPDATE dbo.CaseAssignment SET LatestAssignment = null WHERE EpisodeID  = @EpisodeID
         INSERT INTO [dbo].[CaseAssignment]([EpisodeID],[BenefitWorkerID],[AssignedDateTime],[ActionBy], LatestAssignment)
            VALUES ( @EpisodeID ,@BenefitWorkerID,GetDate(), @CurrentUserID, 1)
    END
	exec [dbo].[spGetInmateProfile] @EpisodeID, @CurrentUserID, 1
END

GO
GRANT EXECUTE ON [dbo].[spSaveAssignment] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spGetApplications
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetApplications]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetApplications]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

	IF EXISTS(SELECT 1 FROM  [dbo].[Application] WHERE ArchivedOnDate IS NOT NULL AND EpisodeID  = @EpisodeID)
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
/*================================================================
   Create procedure spGetBassStaffName
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetBassStaffName]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetBassStaffName]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetBassStaffName]
  @UserID int
 AS	
BEGIN
    SELECT (LastName + ', ' + FirstName + ISNULl(MiddleName, ''))UserName FROM dbo.[User] WHERE IsActive = 1 AND UserID  = @UserID 
END
GO
GRANT EXECUTE ON [dbo].[spGetBassStaffName] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spGetBenefitWorkerAssignedCaseV3
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetBenefitWorkerAssignedCaseV3]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetBenefitWorkerAssignedCaseV3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/*================================================================
   Create procedure spGetEpisodeDropDownListV3
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetEpisodeDropDownListV3]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetEpisodeDropDownListV3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetEpisodeDropDownListV3]
    @SearchString varchar(50) = '',
	@EpisodeID int = 0
AS	
BEGIN
   
IF @searchString <> ''
BEGIN
	DECLARE @search TABLE
	(
		ID int IDENTITY(1,1),
		SubStr nvarchar(100)
	)
	INSERT INTO @search
	Select * FROM [dbo].[fnSplitString](@SearchString, '|')

	DECLARE @HasCDCR int =0
	DECLARE @HasFC int =0
	DECLARE @CDCRLN nvarchar(70) = (Select SubStr from @search WHERE ID = 1)
	DECLARE @PS varchar(5) =(Select SubStr from @search WHERE ID =4)
	DECLARE @FC varchar(4) =(Select SubStr from @search WHERE ID =2)
	DECLARE @BW varchar(5) =(Select SubStr from @search WHERE ID =3)
	DECLARE @OffenderID int
	IF ( @CDCRLN <> '' OR len( @CDCRLN) > 0)
	BEGIN
	   SET @HasCDCR = 1
	   SET @CDCRLN = rtrim(ltrim(@CDCRLN))
	END
	IF @FC <> '' and @FC IS NOT NULL
	   SET @HasFC = 1
	IF @PS = '' OR @PS IS NULL
	   SET @PS = '1'
	IF @BW ='' OR @BW IS NULL
	  SET @BW = '0'

IF @HasCDCR = 1 AND EXISTS(SELECT * FROM Episode WHERE CDCRnum = @CDCRLN)
BEGIN 
   SET @OffenderID = (SELECT OffenderID FROM Episode Where CDCRNum  = @CDCRLN)
SELECT top 100 e.EpisodeID, 
   CONCAT((CASE WHEN ReleaseDate IS NULL THEN 'NA' ELSE CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(), ReleaseDate)) END), 
         ' - ',  e.CDCRNum, ' - ', o.LastName, ', ', o.FirstName, ' ', ISNULL(o.MiddleName, ''))AssignedInmate 
    FROM (SELECT EpisodeID, ReleaseDate, OffenderID, CDCRNum
	        FROM (SELECT EpisodeID, OffenderID, ReleaseDate,CDCRNum, ROW_NUMBER() OVER(PARTITION BY OffenderID ORDER BY EpisodeID DESC) as RowNum 
		            FROM  Episode)e1 Where e1.RowNum =1) e INNER JOIN Offender o on e.OffenderID  =  o.OffenderID Where e.OffenderID  = @OffenderID
END
ELSE
BEGIN
SELECT top 100 e.EpisodeID, 
   CONCAT(e.DayLeft, ' - ',  e.CDCRNum, ' - ', e.UserName)AssignedInmate FROM
(SELECT  e1.EpisodeID, ReLeaseDate,ScreeningDate, AuthToRepresent,ReleaseOfInfoSigned, 
         offenderID, CDCRNum, CustodyFacilityID, ReferralDate,PID, UserName, DayLeft FROM
(SELECT  EpisodeID, ReLeaseDate,ScreeningDate,AuthToRepresent,ReleaseOfInfoSigned,  
        e2.offenderID, CDCRNum, CustodyFacilityID,ReferralDate,o1.PID,
         (o1.LastName + ',' + o1.FirstName + ' ' + ISNULL(o1.MiddleName, ''))UserName,
	(CASE WHEN ReleaseDate IS NULL THEN 'NA' ELSE CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(), ReleaseDate)) END)DayLeft,(ROW_NUMBER() OVER(PARTITION BY e2.offenderID ORDER BY e2.EpisodeID DESC)) RowNum
	 FROM Episode e2 INNER JOIN Offender o1 on e2.OffenderID = o1.OffenderID)e1
  WHERE 
  e1.RowNum = 1 AND ((@HasCDCR = 1 AND CHARINDEX(@CDCRLN, e1.CDCRNum) >0 OR CHARINDEX(@CDCRLN, e1.UserName) >0) OR
     (@HasCDCR = 0 AND ((e1.ReLeaseDate IS NOT NULL AND e1.ReLeaseDate >= DateAdd(day, -31, GetDate()) 
	            AND e1.ReLeaseDate <=DateAdd(day, 120, GetDate()))))))e
		 LEFT OUTER JOIN 
		 (SELECT EpisodeID, BenefitWorkerID, UnAssignedDateTime FROM 
            (SELECT EpisodeID, BenefitWorkerID, UnAssignedDateTime,
			        ROW_NUMBER() OVER(PARTITION BY EpisodeID ORDER BY AssignedDateTime DESC) as RowNum 
			   FROM CaseAssignment)c1 WHERE c1.RowNum=1 and c1.BenefitWorkerID = @BW)c
		 --(SELECT EpisodeID, BenefitWorkerID, UnAssignedDateTime FROM [dbo].[fnCaseAssignmentByBWID](@BW))c
		  on e.EpisodeID = c.EpisodeID
     WHERE ((@HasFC = 1 AND e.CustodyFacilityID= @FC) OR
		   (@HasFC = 0 AND e.EpisodeID=e.EpisodeID)) AND
		   ((@PS = '2' AND e.ScreeningDate IS NULL AND c.UnAssignedDateTime IS NULL) OR
		    (@PS = '3' AND e.ScreeningDate IS NOT NULL AND 
			     (SELECT COUNT(*) FROM Application Where EpisodeID = e.EpisodeID and ArchivedOnDate IS NULL ) = 0) OR
		    (@PS = '4' AND e.ScreeningDate IS NOT NULL AND e.AuthToRepresent = 1 AND 
			                             ReleaseOfInfoSigned = 1) OR
            (@PS = '5' AND 
			     (SELECT  COUNT(*) FROM 
				   (SELECT *, ROW_NUMBER() OVER(PARTITION BY CaseNoteTraceID ORDER BY CaseNoteID DESC) as RowNum FROM CaseNote Where EpisodeID = e.EpisodeID)c1 Where c1.RowNum =1 and (CaseNoteTypeID = 6)) > 0 ) OR 
		    (@PS='1' AND e.EpisodeID=e.EpisodeID)) AND
			((@BW = '0' AND e.EpisodeID=e.EpisodeID) OR (@BW <> '0' AND 
			((@HasCDCR = 1 AND (e.EpisodeID = c.EpisodeID OR c.EpisodeID IS NULL)) OR
			 (@HasCDCR = 0 AND (e.EpisodeID = c.EpisodeID )))))
			Order By e.releasedate, e.DayLeft, e.CDCRNum
END
END
ELSE IF @EpisodeID > 0
BEGIN
 SET @OffenderID = (Select OffenderID FROM Episode Where EpisodeID = @EpisodeID)
 DECLARE @maxEpisodeID int  = (Select Max(EpisodeID) FROM Episode Where OffenderID = @OffenderID)

 SELECT CONVERT(VARCHAR(10), EpisodeID) as Value, CONCAT(
   (CASE WHEN ReleaseDate IS NULL THEN 'NA' ELSE CONVERT(VARCHAR(10),ReleaseDate) END), ' - ', CDCRNum, (CASE WHEN    EpisodeID = @maxEpisodeID THEN '*' ELSE '' END)) as [Text] FROM Episode where offenderID = @OffenderID
   Order by EpisodeID DESC
END
ELSE
BEGIN
SELECT  TOP 100 e.EpisodeID, CONCAT(
   (CASE WHEN e.ReleaseDate IS NULL THEN 'NA' ELSE CONVERT(VARCHAR(5), DATEDIFF(day, GetDate(),e.ReleaseDate)) END), ' - ', CONVERT(VARCHAR(12), o.PID),' - ',
	   e.CDCRNum, ' - ', o.LastName, ',', o.FirstName, ' ', ISNULL(o.MiddleName, ''))AssignedInmate 
  FROM (SELECT EpisodeID, ReLeaseDate, offenderID, CDCRNum, ROW_NUMBER() OVER(PARTITION BY offenderID ORDER BY EpisodeID DESC) as RowNum FROM Episode) e INNER JOIN OFFENDER o ON e.offenderID  =  o.OffenderID
  WHERE  e.RowNum = 1 ORDER BY e.ReleaseDate DESC, LastName, FirstName
 END
END
GO
GRANT EXECUTE ON [dbo].[spGetEpisodeDropDownListV3] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
/*================================================================
   Create procedure spGetInmateProfile
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetInmateProfile]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetInmateProfile]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spGetInmateProfile]
	@EpisodeID int  = 0,
	@CurrentUserID int,
	@All bit = 0
AS
BEGIN
--DECLARE @CDCRNum varchar(6) =  ''  -- 'BF2343'
--DECLARE @EpisodeID int 
DECLARE @SomsUploadID int
DECLARE @CDCRNum varchar(6) = ''
DECLARE @BenefitWorkerID int
DECLARE @OffenderID int = 0
DECLARE @MEpisodeID int  = 0
--DECLARE @CurrentUserID int = 481 --1053
DECLARE @SsiDeterminString nvarchar(200) ='DPW,DPO,DPM,DNM,DPH,DPS,DPV,DKD,DD1,DD2,DD3,DSH,ICF,APU,MHC,EOP,ACU'

IF @EpisodeID = 0
BEGIN
   IF EXISTS(SELECT 1 FROM dbo.CaseAssignment WHERE BenefitWorkerID  = @CurrentUserID AND UnAssignedDateTime IS NULL)
      SELECT @EpisodeID = EpisodeID, @OffenderID  = OffenderID, @CDCRNum = CDCRNum, @SomsUploadID = SomsUploadID FROM dbo.Episode WHERE EpisodeID  =
        (SELECT top 1 EpisodeID FROM dbo.CaseAssignment WHERE BenefitWorkerID  = @CurrentUserID AND UnAssignedDateTime IS NULL ORDER BY AssignedDateTime DESC) 
END
ELSE 
    SELECT @EpisodeID = EpisodeID, @OffenderID  = OffenderID, @CDCRNum = CDCRNum, @SomsUploadID = SomsUploadID FROM dbo.Episode WHere EpisodeID = @EpisodeID


IF @OffenderID  > 0 
  SET @MEpisodeID  =  (SELECT MAX(EpisodeID) FROM dbo.Episode WHERE OffenderID  =  @OffenderID)

SELECT @BenefitWorkerID = BenefitWorkerID FROM dbo.CaseAssignment WHERE EpisodeID = @EpisodeID AND UnAssignedDateTime IS NULL

IF @SomsUploadID > 0
BEGIN
SELECT CDCNumber AS CDCRNum, (CASE WHEN Unit = 'PRCCF' OR Unit ='PUCCF' THEN 
		     (SELECT TOP 1 FacilityID FROM Facility 
			   WHERE OrgCommonID = Unit and Disabled <> 1 and substring(SomsLoc, CHARINDEX( '-', SomsLoc)+1, len(SomsLoc)) = substring(Loc, CHARINDEX( '-', Loc)+1, len(Loc)))
             ELSE (SELECT TOP 1 FacilityID FROM Facility WHERE OrgCommonID = Unit and Disabled <> 1) END)CustodyFacilityID
      ,(CASE WHEN ScheduledReleaseDate IS NOT NULL THEN Convert(varchar,ScheduledReleaseDate, 101) ELSE null END)SomsReleaseDate, InmateLastName AS LastName ,InmateFirstName AS FirstName
      ,(select GenderID from Gender where Code= InmateSexCode)GenderID, CellBed AS Housing, SSNum AS SSN,FileDate,InmateDateOfBirth AS DOB
	  ,(CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END)EOP
	  ,(CASE WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END)CCCMS
	  ,(CASE WHEN len(ISNULL(PENALCODE, '')) >0 THEN 1 ELSE 0 END)PC290, 0 AS PC457 
      ,(CASE WHEN DevelopDisabledEvaluation in ('DD1', 'DD2', 'DD3') THEN 1 ELSE 0 END)DevDisabled
      ,(CASE WHEN ISNULL(DPPHearingCode,'')<>'' or ISNULL(DPPMobilityCode, '')<>'' or ISNULL(DPPSpeechCode, '')<>'' or ISNULL(DPPVisionCode, '')<>'' THEN 1 ELSE 0 END)PhysDisabled
      ,(CASE WHEN DPPHearingCode = 'DPH' OR DPPMobilityCode in ('DPM', 'DPO', 'DPW') OR DPPSpeechCode = 'DPS' OR DPPVisionCode = 'DPV'  THEN 1 ELSE 0 END )MedPlacement
      ,(CASE WHEN  (CHARINDEX(DPPMobilityCode, @SsiDeterminString) > 0  OR  
					CHARINDEX(DPPHearingCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPSpeechCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPVisionCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DevelopDisabledEvaluation, @SsiDeterminString) > 0  OR
					CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0) AND DevelopDisabledEvaluation <> 'NCF' THEN 1 ELSE 0 END)SSI, (CASE WHEN Lifer = 'Y' THEN 1 ELSE 0 END)Lifer
      ,(CASE WHEN ISNULl(CountyOfRelease, '') <> '' AND EXISTS(select 1 from County where Name =CountyOfRelease) THEN 
			         (select CountyID from County where Name =CountyOfRelease) ELSE NULL END)ReleaseCountyID, ISNULL(PAROLEUNIT, '')ParoleUnit
      ,(CASE WHEN PAROLEAGENTLASTNAME is NOT null AND PAROLEAGENTLASTNAME <> '' THEN
			 PAROLEAGENTLASTNAME +  ', ' + ISNULL(PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(PAROLEAGENTMIDDLENAME, '')
			 ELSE ISNULL(PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(PAROLEAGENTMIDDLENAME, '') END)ParoleAgent
FROM [dbo].[SomsRecord] WHERE CDCNumber = @CDCRNum AND SomsUploadID = @SomsUploadID
END
ELSE
BEGIN
 SELECT @CDCRNum AS CDCRNum,  null AS CustodyFacilityID, null AS SomsReleaseDate,''LastName,'' AS FirstName, null AS GenderID, null AS Housing, null AS SSN
        ,null AS FileDate, null AS DOB,0 AS EOP, 0 AS CCCMS, 0 AS PC290, 0 AS PC457, 0 AS DevDisabled, 0 AS PhysDisabled, 0 AS MedPlacement, 0 AS SSI
		,0 AS Lifer, null AS ReleaseCountyID, ''ParoleUnit,''ParoleAgen
END

IF ISNULL(@EpisodeID, 0) > 0
BEGIN
SELECT e.EpisodeID, e.CDCRNum, e.OffenderID, (CASE WHEN ISNULL(@SomsUploadID, 0) > 0 THEN 1 ELSE 0 END)SomsDataExists, (CASE WHEN o.ReviewStatus = 1 THEN 1 ELSE 0 END)SomsFlagged, 
       (CASE WHEN ISNULL(@BenefitWorkerID, 0) > 0 THEN 1 ELSE 0 END)CaseAssigned, o.LastName, o.FirstName, o.MiddleName,o.PC290, o.PC457, o.USVet, o.ReviewStatus,
	   o.SSN, o.DOB, o.GenderID, o.LongTermMedCare, o.Hospice, o.AssistedLiving, o.HIVPos, o.ChronicIllness, o.EOP, o.CCCMS, o.Elderly, o.PhysDisabled, o.DevDisabled,
	   o.DSH, o.SSI, o.VRSS, e.Lifer, e.ReleaseCountyID, e.CustodyFacilityID, e.ScreeningDate, e.AuthToRepresent, e.ReleaseOfInfoSigned, e.EpisodeAcpDshTypeID, 
	   e.EpisodeMdoSvpTypeID, e.EpisodeMedReleaseTypeID, e.ReleasedToPRCS, e.CIDServiceRefusalDate, e.ReferralDate, e.ReleaseDate, e.Housing, e.ParoleUnit,
	   e.ParoleAgent, @BenefitWorkerID AS BenefitWorkerID,e.ScreeningDateSetByUserID,e._CIDServicePlanDate_Disabled,
	     e.FileDate, e.CalFreshRef, e.CalWorksRef,e.DHCSEligibility, e.DHCSEligibilityDate,e.DestinationID, o.MedPlacement,
	   (CASE WHEN ISNULL(@BenefitWorkerID, 0) > 0 THEN (SELECT (LastName + ',' + FirstName + ISNULL(MiddleName, '')) FROM dbo.[User] WHERE UserID  = @BenefitWorkerID) ELSE null END)BenefitWorkerName
FROM dbo.Episode e INNER JOIN dbo.Offender o ON e.OffenderID  = o.OffenderID AND e.EpisodeID  = @EpisodeID
SELECT EpisodeID, (CASE WHEN EpisodeID = @MEpisodeID THEN Convert(varchar,ReferralDate, 101) + '*' ELSE Convert(varchar,ReferralDate, 101) END)ReferralDate 
  FROM dbo.Episode WHERE OffenderID  = @OffenderID GROUP BY EpisodeID, ReferralDate  ORDER BY EpisodeID DESC
END
ELSE
BEGIN
 SELECT 0 AS EpisodeID, 0 AS OffenderID, ''CDCRNum, (CASE WHEN ISNULL(@SomsUploadID, 0) > 0 THEN 1 ELSE 0 END)SomsDataExists, 0 AS SomsFlagged, 
       0 AS CaseAssigned, ''LastName, ''FirstName, ''MiddleName, 0 AS PC290, 0 AS PC457, 0 AS USVet, 0 AS ReviewStatus,
	   0 AS SSN, null AS DOB, null AS GenderID,  0 AS LongTermMedCare, 0 AS Hospice, 0 AS AssistedLiving, 0 AS HIVPos, 0 AS ChronicIllness, 0 AS EOP, 0 AS CCCMS, 
	   0 AS Elderly, 0 AS PhysDisabled, 0 AS DevDisabled, 0 AS DSH, 0 AS SSI, 0 AS VRSS, 0 AS Lifer, null AS ReleaseCountyID, null AS CustodyFacilityID, 
	   null AS ScreeningDate, 0 AS AuthToRepresent, 0 AS ReleaseOfInfoSigned, null AS EpisodeAcpDshTypeID, null AS EpisodeMdoSvpTypeID, null AS EpisodeMedReleaseTypeID, 
	   null AS ReleasedToPRCS, null AS CIDServiceRefusalDate, null AS ReferralDate, null AS ReleaseDate, ''Housing,''ParoleUnit, ''ParoleAgent, null AS BenefitWorkerID,
	   null AS ScreeningDateSetByUserID,null AS _CIDServicePlanDate_Disabled, null AS DestinationID, 0 AS MedPlacement, null AS FileDate,null AS CalFreshRef, null AS CalWorksRef,
	   null AS DHCSEligibility, null AS DHCSEligibilityDate,null AS BenefitWorkerName
 SELECT 0 AS EPisodeID, ''ReferralDate
END
	   
SELECT CountyID, Name From dbo.County
SELECT FacilityID, (OrgCommonID + '-' + Name)NameWithCode, Abbr FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0 
SELECT GenderID, Code, Name FROM dbo.Gender WHERE ISNULL(Disabled, 0) = 0 
SELECT EpisodeAcpDshTypeID, Name FROM dbo.EpisodeAcpDshType 
SELECT EpisodeMdoSvpTypeID, Name FROM dbo.EpisodeMdoSvpType
SELECT EpisodeMedReleaseTypeID, Name FROM dbo.EpisodeMedReleaseType
SELECT lkValue, lkdescr_short  FROM dbo.LookUpTable WHERE ISNULL(Disabled, 0) = 0 

IF @All =  1
    EXEC [dbo].[spGetApplications] @EpisodeID, @CurrentUserID

END
GO
GRANT EXECUTE ON [dbo].[spGetInmateProfile] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
/*================================================================
   Create procedure spGetSearchingList
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetSearchingList]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetSearchingList]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
/*================================================================
   Create procedure spGetUploadedFiles
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetUploadedFiles]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetUploadedFiles]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spGetUploadedFiles]
  @EpisodeID int  
 AS	
BEGIN

	SELECT t1.ID, t1.EpisodeId, t1.FileName, (t1.[FileSize] / 1024)FileSize, t1.DateAction AS UploadDate, 
	       (t2.Lastname + ', ' + t2.FirstName + ' ' + ISNULl(t2.MiddleName, ''))UploadBy 
	  FROM [dbo].[DocUpload] t1 INNER JOIN dbo.[User] t2 ON t1.ActionBy = t2.UserID
	 WHERE EpisodeID =  @EpisodeID AND ISNULL(t1.ActionStatus, 0) <> 10
End
GO
GRANT EXECUTE ON [dbo].[spGetUploadedFiles] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spGetUserAndTeamAppsWorked
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetUserAndTeamAppsWorked]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetUserAndTeamAppsWorked]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
/*================================================================
   Create procedure spGetUserAndTeamCasesWorked
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetUserAndTeamCasesWorked]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetUserAndTeamCasesWorked]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 /*================================================================
   Create procedure spGetUserAppsWorked
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetUserAppsWorked]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetUserAppsWorked]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetUserAppsWorked]
  @UserID int,
  @StartDate DateTime,
  @EndDate DateTime
 AS	
BEGIN
 --DECLARE @UserID  int = 1018
 --DECLARE @StartDate DateTime = '2017-01-01'
 --DECLARE @EndDate DateTime = '2017-03-01'
 IF EXISTS(SELECT AssignedDateTime FROM dbo.CaseAssignment
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
GRANT EXECUTE ON [dbo].[spGetUserAppsWorked] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
 /*================================================================
   Create procedure spGetUserByUsername
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetUserByUsername]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetUserByUsername]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetUserByUsername]
	-- Add the parameters for the stored procedure here
	@Username nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [User] WHERE Username = @Username
END
GO
GRANT EXECUTE ON [dbo].[spGetUserByUsername] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spTeamWorkLocationList
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spTeamWorkLocationList]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spTeamWorkLocationList]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spTeamWorkLocationList]
    @StartDate DateTime,
	@EndDate DateTime,
	@UserID int = 0
AS	
BEGIN
    SELECT t1.UserID, t1.PageLoadId, t1.IpAddress, (t1.Action + ' at : ' + ISNULL(t2.LocationAbbr, ISNULl(t1.IpAddress, 'Unknown')))Title,
	'Team meneber location' Description, Convert(datetime, t1.DateTimeOffset) as Start, DateAdd(hour, 1, Convert(datetime, t1.DateTimeOffset)) as [End]
  from PageLoad t1 left outer join [tlkpIpAddressMap] t2 on substring(t1.IpAddress,1, len(t2.IpAddress)-1) 
   = substring(t2.IpAddress,1, len(t2.IpAddress)-1) Where t1.UserID  = @UserID and t1.Method = 'POST' AND
   t1.DateTimeOffset >= @StartDate AND t1.DateTimeOffset <=@EndDate 
END 
GO
GRANT EXECUTE ON [dbo].[spTeamWorkLocationList] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spGetApplicationByType
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetApplicationByType]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetApplicationByType]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
/*================================================================
   Create procedure spRptBWProductivityV3
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spRptBWProductivityV3]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spRptBWProductivityV3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRptBWProductivityV3]
	@FromDate DateTime = NULL,
	@ToDate DateTime = NULL,
	@BfWorkerIDs nvarchar(200) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from.
	SET NOCOUNT ON;

	IF @FromDate IS NULL 
	   SET @FromDate = DateAdd(YEAR, -1, GetDate())

	IF @ToDate is NULL 
	  SET @ToDate = GetDate()

	  --if @BfWorkerIDs = ''
	  --  SET @BfWorkerIDs = '1000, 1001, 1002'
   
   --DECLARE @FromDate DateTime = '2020-12-01'
   --DECLARE @ToDate DateTime = '2021-04-30' --DateAdd(YEAR, 1, GetDate())
   --DECLARE @BfWorkerIDs nvarchar(200) = '172,168,152,1006,1024,1020,1015,1033,1248,1052'
   
   DECLARE @tempUser TABLE(
     BenefitWorkerID int primary key,
	 BenefitWorkerName varchar(70)
   )
   INSERT INTO @tempUser
   Select UserID, (LastName + ', ' + (Substring(FirstName, 1, 1) + '.'))BfWorkerName From [User] Where UserID in
   (select splitdata from [dbo].[fnSplitString](@BfWorkerIDs, ','))
   --select * from @tempUser
  DECLARE @tempCollection TABLE (
      EpisodeID int default 0 primary key,  
      BenefitWorkerId int default 0 ,
      BenefitWorkerName varchar(70),  
	  CDCRNum varchar(6),
	  ClientName nvarchar(70),
	  ServicesNotProvided int default 0, 
	  MediCalSubmission int default 0,
	  SsiSubmission int default 0, 
      VaSubmission int default 0,
	  SSIBnp int default 0, 
	  VABnp int default 0,
	  MediCalBnp int default 0
)

--initail insert episode benefit worker to the #tempCollection 
 INSERT INTO @tempCollection (EpisodeID, BenefitWorkerID, BenefitWorkerName)
  SELECT t1.EpisodeID,t1.BenefitWorkerID, t2.BenefitWorkerName FROM CaseAssignment t1 INNER JOIN @tempUser t2 ON t1.BenefitWorkerID = t2.BenefitWorkerID 
   WHERE t1.LatestAssignment =  1 AND t1.AssignedDateTime >= @FromDate AND t1.AssignedDateTime <= @ToDate
   UNION
   SELECT EpisodeID, UserID, BenefitWorkerName FROM 
   (SELECT t1.EpisodeID, t1.UserID, t2.BenefitWorkerName,
    ROW_NUMBER() OVER(PARTITION BY EpisodeID ORDER BY CaseNoteID DESC) AS RowNum FROM CaseNote t1 
	INNER JOIN @tempUser t2 ON t1.UserID = t2.BenefitWorkerID 
	Where t1.EventDate > = @FromDAte AND t1.EventDate <=@ToDate AND t1.ActionStatus != 10 AND
	t1.CaseNoteTypeReasonID IN (3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 37, 43, 46, 47, 19, 20, 21, 22, 23, 24, 25, 26, 27, 30, 31, 32, 33))t WHERE t.RowNum = 1

UPDATE tgr  SET CDCRNum = scr.CDCRNum , ClientName = scr.ClientName FROM
  @tempCollection tgr INNER JOIN 
  (SELECT e.EpisodeID, e.CDCRNum, (o.FirstName + ' ' + o.LastName)ClientName FROM Episode e INNER JOIN Offender o ON e.OffenderID  = o.offenderID WHERE e.LatestEpisode = 1)scr on   tgr.EpisodeID  =  scr.EpisodeID

 --   INNER JOIN  
	--(Select EpisodeID, CDCRNum, (o.FirstName + ' ' + o.LastName)ClientName FROM (SELECT EpisodeID, CDCRNum, OffenderID FROM
 --   (SELECT EpisodeID,CDCRNum, OffenderID, ROW_NUMBER() OVER(PARTITION BY OffenderID ORDER BY EpisodeID DESC) AS RowNum FROM Episode)e1 WHERE e1.Rownum =1) e  INNER JOIN Offender o 
	--    ON e.OffenderId = o.OffenderID)E ON TS.EpisodeID  = E.EpisodeID
--select * FROM @tempCollection Order BY EpisodeID
Update  T SET T.MediCalSubmission = N.MediCalApps, T.SsiSubmission = N.SsiApps, T.VaSubmission = N.VaApps	  
  FROM @tempCollection T INNER JOIN
 (SELECT distinct EpisodeID, sum(MediCalApps)MediCalApps, sum(SsiApps)SsiApps, sum(VaApps)VaApps,CreatedByUserID
  FROM
(SELECT EpisodeID, CreatedByUserID,
     (CASE WHEN ApplicationTypeID = 2 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as MediCalApps,
	 (CASE WHEN ApplicationTypeID = 0 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as SsiApps,
	 (CASE WHEN ApplicationTypeID = 1 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as VaApps
   FROM APPLICATION  WHERE AppliedOrRefusedOnDate >= DateAdd(Year, -1, @FromDate) AND AppliedOrRefusedOnDate <= @ToDate AND ArchivedOnDate IS NULL AND CreatedByUserID IS NOT NULL) G1    
   Group By G1.EpisodeID, CreatedByUserID) N  ON T.EpisodeID =  N.EpisodeID 
   Where N.CreatedByUserID = T.BenefitWorkerId
  
--get data from casenote per selected benefit worker
Update  T SET T.ServicesNotProvided = J.ServicesNotProvided, T.MediCalBnp = J.MediCalBnp, T.SSIBnp = J.SSIBnp, T.VABnp = J.VABnp
  FROM @tempCollection T INNER JOIN
   (SELECT EpisodeID, sum(ISNULL(ServicesNotProvidedOther, 0) + ISNULL(ServicesNotProvidedRefused, 0))ServicesNotProvided, 
			sum(MediCalBnp)MediCalBnp, sum(SSIBnp) SSIBnp, sum(VABnp)VABnp, UserID
 FROM 
(SELECT Q.EpisodeID, Q.UserID,
   (CASE WHEN Q.CaseNoteTypeID = 6 and Q.CaseNoteTypeReasonID = 7 THEN 1 ELSE 0 END) as ServicesNotProvidedOther,
   (CASE WHEN Q.CaseNoteTypeID = 6 and Q.CaseNoteTypeReasonID IN (8, 9, 10, 11, 12, 37, 43, 46, 47) THEN 1 ELSE 0 END) as ServicesNotProvidedRefused,
   (CASE WHEN Q.CaseNoteTypeID = 5 and Q.CaseNoteTypeReasonID in (3, 4, 5, 6)  THEN 1 ELSE 0 END) as MediCalBnp,
   (CASE WHEN Q.CaseNoteTypeID = 8 and Q.CaseNoteTypeReasonID in (19, 20, 21, 22, 23, 24, 25, 26, 27)  THEN 1 ELSE 0 END) as SSIBnp,
   (CASE WHEN Q.CaseNoteTypeID = 10 and Q.CaseNoteTypeReasonID in (30, 31, 32, 33)  THEN 1 ELSE 0 END) as VABnp   
 FROM 
 (SELECT EpisodeID, CaseNoteTypeID, CaseNoteTypeReasonID, EventDate, UserID FROM 
  (SELECT EpisodeID, CaseNoteTypeID, CaseNoteTypeReasonID, EventDate, UserID,
    ROW_NUMBER() OVER(PARTITION BY EpisodeID, CaseNoteTraceID ORDER BY CaseNoteID DESC) AS RowNum FROM CASENOTE 
	Where EventDate > = DateAdd(YEAR, -1, @FromDAte) AND EventDate <=@ToDate 
	AND ActionStatus != 10) d  WHERE d.RowNum = 1) Q 
	GROUP BY Q.EpisodeID, Q.CaseNoteTypeID, Q.CASENoteTYPEreasonID, Q.EventDate, Q.UserID) R GROUP BY R.EpisodeID, R.UserID) J on T.EpisodeID = J.EpisodeID AND T.BenefitWorkerID =  J.UserID
	
--SELECT BenefitWorkerId, BenefitWorkerName, EpisodeID, CDCRNum, ClientName, ServicesNotProvided, MediCalSubmission, SsiSubmission, VaSubmission, MediCalBnp, SSIBnp, VABnp from @tempCollection

SELECT BenefitWorkerId, BenefitWorkerName, EpisodeID, ClientName, CDCRNum, 
       MediCalSubmission AS MCTotal, SsiSubmission AS SSITotal, VaSubmission AS VATotal, 
	   ServicesNotProvided AS SNPRTotal, MediCalBnp, SSIBnp, VABnp from @tempCollection
END
GO
GRANT EXECUTE ON [dbo].[spRptBWProductivityV3] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spRptProductivityV3
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spRptProductivityV3]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spRptProductivityV3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spRptProductivityV3]
	@FromDate DateTime = NULL,
	@ToDate DateTime = NULL,
	@BfWorkerIDs nvarchar(200) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from.
	SET NOCOUNT ON;

	IF @FromDate IS NULL 
	   SET @FromDate = DateAdd(YEAR, -1, GetDate())

	IF @ToDate is NULL 
	  SET @ToDate =  DateAdd(Month, 3, @FromDate)

	  --if @BfWorkerIDs = ''
	  --  SET @BfWorkerIDs = '1000, 1001, 1002'
   
 --  DECLARE @FromDate DateTime = '2017-03-01'
	--DECLARE @ToDate DateTime = '2017-07-31' --DateAdd(YEAR, 1, GetDate())
	--DECLARE @BfWorkerIDs nvarchar(200) = '172,168,152,1006,1024,1020,1015,1033'
   
   DECLARE @tempUser TABLE(
     BenefitWorkerID int primary key,
	 BenefitWorkerName varchar(70)
   )
   INSERT INTO @tempUser
   Select UserID, (LastName + ', ' + (Substring(FirstName, 1, 1) + '.'))BfWorkerName From [User] Where UserID in
   (select splitdata from [dbo].[fnSplitString](@BfWorkerIDs, ','))
   --select * from @tempUser
 DECLARE @tempCollection TABLE(
      EpisodeID int not null,
      OffenderID int default 0, CDCRNum varchar(6), ReleaseDate DateTime NULL, HIVPos bit,
	  County varchar(25) default '', ReleaseTo varchar(20) default '', BenefitWorkerName varchar(70), ScreeningDate DateTime NULL, 
	  MediCalDate DateTime NULL,SsiDate DateTime NULL, VaDate DateTime NULL, CentralFileReview int default 0,CaseManagement int default 0,
	  FaceToFace int default 0, MedicalFileReview int default 0, CaseAssigned int default 0, TcmpChrono int default 0, OutcomeLetter DateTime NULL,
	  CidCreated int default 0, CidDelivered DateTime NULL, CidDeliveredCount int default 0, StatusCheckOrUpdate int default 0, ExitInterview int default 0, 
	  TelInterview DateTime NULL, ExtInterview DateTime NULL, ServicesNotProvided int default 0, ServicesNotProvidedRefused int default 0,
	  ServicesNotProvidedOther int default 0, MediCalSubmission int default 0,SsiSubmission int default 0, OutcomeLetterCount int default 0,
	  VaSubmission int default 0,SSIBnp int default 0, VABnp int default 0,MediCalBnp int default 0, MediCalCode char(1) default '',
      SSICode char(1) default '', VACode char(1) default '', MediCalFa varchar(10) default '', SsiFa varchar(10) default '', VaFa varchar(10) default '', 
	  BenefitWorkerID int default 0, MediCalDiscrepancy bit,SsiDiscrepancy bit,  VaDiscrepancy bit, CIDDiscrepancy bit,
	  ApplicationDate DateTime NULL, MSubmission int default 0, SSubmission int default 0, VSubmission int default 0, SignedCid int default 0,
	  MediCalApps int default 0, SsiApps int default 0, VaApps int default 0, 
	  MaxMediCalDate DateTime NULL, MaxSsiDate DateTime NULL, MaxVaDate DateTime NULL, 
	  TotalMedicalApps int default 0, TotalSSIApps int default 0, TotalVAApps int default 0,
	  TotalMediCalSubmission int default 0, TotalSsiSubmission int default 0, TotalVaSubmission int default 0,
	  TotalMSubmission int default 0, TotalSSubmission int default 0, TotalVSubmission int default 0,
	  TotalServicesNotProvided int default 0, TotalServicesNotProvidedRefused int default 0,
	  TotalSSIBnp int default 0, TotalVABnp int default 0, TotalMediCalBnp int default 0
 )

 INSERT INTO @tempCollection (EpisodeID, BenefitWorkerID, BenefitWorkerName)
 SELECT t1.EpisodeID, t1.BenefitWorkerID, t3.BenefitWorkerName 
  FROM CaseAssignment t1 INNER JOIN Episode t2 on t1.EpisodeID = t2.EpisodeID INNER JOIN @tempUser t3 on t1.BenefitWorkerID = t3.BenefitWorkerID 
     Where t1.AssignedDateTime >= @FromDate AND AssignedDateTime <= @ToDate AND t1.LatestAssignment = 1 AND t2.LatestEpisode = 1
	 union
 SELECT distinct n.EpisodeID, n.UserID, n1.BenefitWorkerName FROM
   (SELECT EpisodeID, UserID,
    ROW_NUMBER() OVER(PARTITION BY CaseNoteTraceID, EpisodeID ORDER BY CaseNoteID  DESC) AS RowNum FROM CASENOTE 
	Where EventDate > = @FromDate AND EventDate <=@ToDate AND ActionStatus != 10) n INNER JOIN Episode n2 ON n.EpisodeID = n2.EpisodeID 
	    INNER JOIN  @tempUser n1 ON n.UserID = n1.BenefitWorkerID Where n.RowNum = 1 AND n2.LatestEpisode = 1 --Order By EpisodeID, n.userID
 
-- add offender information from episode 
Update T SET T.OffenderID = E.OffenderID, T.CDCRNum= E.CDCRNum, T.ReleaseDate = E.ReleaseDate, T.County= E.County,
 T.ReleaseTo = E.ReleaseTo, T.ScreeningDate = E.ScreeningDate, T.SSICode = E.SSICode, T.VACode = E.VACode, T.HIVPos = E.HIVPos
FROM @tempCollection T INNER JOIN
 (SELECT e.EpisodeID, e.OffenderID, e.CDCRNum, e.ReleaseDate, (CASE WHEN ISNULL(e.ReleaseCountyID, 0) = 0 THEN '' 
	        ELSE (SELECT NAME FROM County Where CountyID =  e.ReleaseCountyID) END) as County,
  (CASE WHEN DestinationID = 1 THEN 'PRCS'
		WHEN DestinationID = 2 THEN 'Parole'
		WHEN DestinationID = 3 THEN 'Discharged'
		WHEN DestinationID = 4 THEN 'ACP'
		WHEN DestinationID = 5 THEN 'MDO/SVP'
		WHEN DestinationID = 6 THEN 'INS/ICE'
		WHEN DestinationID = 7 THEN 'OutOfState' ELSE 'Unknown' END) as ReleaseTo,
    e.ScreeningDate, (CASE WHEN o.SSI = 1 THEN 'Y' ELSE '' END) AS SSICode, 
   (CASE WHEN o.USVet = 1 OR o.VRSS = 1 THEN 'Y' ELSE '' END) as VACode, o.HIVPos  	
   FROM Episode e inner join Offender o on e.OffenderID = o.OffenderID) E ON E.EpisodeID = T.EpisodeID
   --select * from #tempCollection
--add application information specified for the selected benefit worker
Update  T SET T.SsiDate = N.SsiDate, T.VaDate = N.VaDate, T.MediCalDate = N.MedicalDate, T.SsiFa = N.SsiFa, T.MediCalFa = N.MediCalFa, 
      T.VaFa = N.VaFa, T.MediCalApps = N.MediCalApps, T.SsiApps = N.SsiApps, T.VaApps = N.VaApps,
	  T.MaxSsiDate = N.SsiDate, T.MaxVaDate = N.VaDate, T.MaxMediCalDate = N.MedicalDate, T.TotalMedicalApps = N.MediCalApps, T.TotalSSIApps = N.SsiApps, T.TotalVAApps = N.VaApps
  FROM @tempCollection T INNER JOIN
 (SELECT distinct EpisodeID,  MAX(SsiDate)SsiDate, MAX(vaDate)VaDate, Max(MedicalDate)MedicalDate, MAX(SsiFa)SsiFa, MAX(VaFa)VaFa, 
  MAX(MediCalFa)MediCalFa, sum(MediCalApps)MediCalApps, sum(SsiApps)SsiApps, sum(VaApps)VaApps,CreatedByUserID
  FROM
(SELECT EpisodeID,  (CASE WHEN ApplicationTypeID = 0 AND AppliedOrRefusedOnDate IS NOT NULL THEN AppliedOrRefusedOnDate ELSE NULL END)  as SsiDate,
     (CASE WHEN ApplicationTypeID = 1 AND AppliedOrRefusedOnDate IS NOT NULL THEN AppliedOrRefusedOnDate ELSE NULL END)  as VaDate,
	 (CASE WHEN ApplicationTypeID = 2 AND AppliedOrRefusedOnDate IS NOT NULL THEN AppliedOrRefusedOnDate ELSE NULL END) as MedicalDate,
     (CASE WHEN ApplicationTypeID = 0 AND ISNULL(CustodyFacilityId, 0) > 0 THEN (SELECT Abbr FROM Facility Where FacilityID = CustodyFacilityId) ELSE '' END) as SsiFa,
	 (CASE WHEN ApplicationTypeID = 1 AND ISNULL(CustodyFacilityId, 0) > 0 THEN (SELECT Abbr FROM Facility Where FacilityID = CustodyFacilityId) ELSE '' END) as VaFa,
	 (CASE WHEN ApplicationTypeID = 2 AND ISNULL(CustodyFacilityId, 0) > 0 THEN (SELECT Abbr FROM Facility Where FacilityID = CustodyFacilityId) ELSE '' END) as MediCalFa,
	 (CASE WHEN ApplicationTypeID = 2 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as MediCalApps,
	 (CASE WHEN ApplicationTypeID = 0 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as SsiApps,
	 (CASE WHEN ApplicationTypeID = 1 AND AgreesToApply = 1 THEN 1 ELSE 0 END) as VaApps, CreatedByUserID
   FROM APPLICATION  WHERE AppliedOrRefusedOnDate >= DateAdd(Year, -1, @FromDate) AND 
   AppliedOrRefusedOnDate <= @ToDate AND CreatedByUserID IS NOT NULL) G1 Group By G1.EpisodeID, CreatedByUserID) N  ON T.EpisodeID =  N.EpisodeID AND T.BenefitWorkerID  = N.CreatedByUserID 

--get data from casenote per selected benefit worker
Update  T SET T.TotalServicesNotProvidedRefused =  J.ServicesNotProvidedRefused, T.TotalServicesNotProvided = J.ServicesNotProvided, 
    T.TotalMediCalSubmission = J.MediCalSubmission, T.TotalMSubmission = J.MSubmission, T.TotalSsiSubmission = J.SsiSubmission, T.TotalSSubmission = J.SSubmission, 
	T.TotalVaSubmission = J.VaSubmission, T.TotalVSubmission = J.VSubmission,
    T.CentralFileReview = J.CentralFileReview, T.CaseManagement = J.CaseManagement, T.ExitInterview = J.ExitInterview, 
    T.FaceToFace = J.FaceToFace, T.MedicalFileReview = J.MedicalFileReview, T.CaseAssigned = J.CaseAssigned, T.TcmpChrono = J.TcmpChrono,
	T.OutcomeLetterCount =J.OutcomeLetterCount, T.CidCreated = J.CidCreated, T.CidDeliveredCount = J.CidDeliveredCount,
	T.StatusCheckOrUpdate = J.StatusCheckOrUpdate, T.ServicesNotProvidedRefused =  J.ServicesNotProvidedRefused, 
	T.ServicesNotProvided = J.ServicesNotProvided, T.MediCalSubmission = J.MediCalSubmission, T.MSubmission = J.MSubmission, 
	T.SsiSubmission = J.SsiSubmission, T.SSubmission = J.SSubmission, T.VaSubmission = J.VaSubmission, T.VSubmission = J.VSubmission,
	T.MediCalBnp = J.MediCalBnp, T.SSIBnp = J.SSIBnp, T.VABnp = J.VABnp, T.SignedCid = J.SignedCid, T.OutcomeLetter = J.OutcomeLetter,
	T.ExtInterview = J.ExtInterview, T.CidDelivered = J.CidDelivered, T.TelInterview = J.TelInterview, T.MediCalCode = J.MediCalCode
  FROM @tempCollection T INNER JOIN
   (SELECT EpisodeID, sum(CentralFileReview)CentralFileReview, sum(CaseManagement)CaseManagement, 
	        sum(ExitInterview)ExitInterview, sum(FaceToFace)FaceToFace, sum(MedicalFileReview)MedicalFileReview,
			sum(CaseAssigned)CaseAssigned, sum(TcmpChrono)TcmpChrono,sum(OutcomeLetterCount)OutcomeLetterCount,
			sum(CidCreated)CidCreated, sum(CidDeliveredCount)CidDeliveredCount, sum(StatusCheckOrUpdate)StatusCheckOrUpdate,
	        sum(ServicesNotProvidedRefused)ServicesNotProvidedRefused, sum(ServicesNotProvidedOther)ServicesNotProvidedOther,
			sum(ServicesNotProvidedOther + ServicesNotProvidedRefused) ServicesNotProvided, 
			(CASE WHEN sum(ServicesNotProvidedOther + ServicesNotProvidedRefused) > 0 THEN 0 ELSE 
			  sum(MediCalSubmission) END)MediCalSubmission, sum(MediCalSubmission)MSubmission,
			(CASE WHEN sum(ServicesNotProvidedOther + ServicesNotProvidedRefused) > 0 THEN 0 ELSE 
			  sum(SsiSubmission) END)SsiSubmission, sum(SsiSubmission)SSubmission, 
			(CASE WHEN sum(ServicesNotProvidedOther + ServicesNotProvidedRefused) > 0 THEN 0 ELSE 
			  sum(VaSubmission) END)VaSubmission, sum(VaSubmission)VSubmission,
			sum(MediCalBnp)MediCalBnp, sum(SSIBnp) SSIBnp, sum(VABnp)VABnp, 
			sum(SignedCid)SignedCid, MAX(OutcomeLetter)OutcomeLetter, MAX(ExtInterview)ExtInterview,
			MAX(CidDelivered)CidDelivered, MAX(TelInterview)TelInterview,
			(CASE WHEN sum(ServicesNotProvidedOther + ServicesNotProvidedRefused) > 0 THEN '' ELSE 'Y' END) AS MediCalCode, UserID
 FROM 
(SELECT Q.EpisodeID, 
   (CASE WHEN Q.CaseNoteTypeID = 0 THEN 1 ELSE 0 END) as CentralFileReview,
   (CASE WHEN Q.CaseNoteTypeID = 1 THEN 1 ELSE 0 END) as CaseManagement,
   (CASE WHEN Q.CaseNoteTypeID = 2 THEN 1 ELSE 0 END) as ExitInterview,
   (CASE WHEN Q.CaseNoteTypeID = 3 THEN 1 ELSE 0 END) as FaceToFace,
   (CASE WHEN Q.CaseNoteTypeID = 4 THEN 1 ELSE 0 END) as MedicalFileReview,
   (CASE WHEN Q.CaseNoteTypeID = 11 THEN 1 ELSE 0 END) as CaseAssigned,
   (CASE WHEN Q.CaseNoteTypeID = 12 THEN 1 ELSE 0 END) as TcmpChrono,
   (CASE WHEN Q.CaseNoteTypeID = 13 THEN 1 ELSE 0 END) as OutcomeLetterCount,
   (CASE WHEN Q.CaseNoteTypeID = 16 THEN 1 ELSE 0 END) as CidCreated,
   (CASE WHEN Q.CaseNoteTypeID = 17 THEN 1 ELSE 0 END) as CidDeliveredCount,
   (CASE WHEN Q.CaseNoteTypeID = 19 THEN 1 ELSE 0 END) as StatusCheckOrUpdate,
   (CASE WHEN Q.CaseNoteTypeID = 13 THEN Q.EventDate ELSE NULL END) as OutcomeLetter,
   (CASE WHEN Q.CaseNoteTypeID = 2 THEN Q.EventDate ELSE NULL END) as ExtInterview,
   (CASE WHEN Q.CaseNoteTypeID = 17 THEN Q.EventDate ELSE NULL END) as CidDelivered,
   (CASE WHEN Q.CaseNoteTypeID = 8 and Q.CaseNoteTypeReasonID =16 THEN Q.EventDate ELSE NULL END) as TelInterview,
   (CASE WHEN Q.CaseNoteTypeID = 6 and Q.CaseNoteTypeReasonID = 7 THEN 1 ELSE 0 END) as ServicesNotProvidedOther,
   (CASE WHEN Q.CaseNoteTypeID = 6 and Q.CaseNoteTypeReasonID IN (8, 9, 10, 11, 12, 37, 43, 46, 47) THEN 1 ELSE 0 END) as ServicesNotProvidedRefused,
   (CASE WHEN Q.CaseNoteTypeID = 5 and Q.CaseNoteTypeReasonID in (1, 42)  THEN 1 ELSE 0 END) as MediCalSubmission,
   (CASE WHEN Q.CaseNoteTypeID = 5 and Q.CaseNoteTypeReasonID in (3, 4, 5, 6)  THEN 1 ELSE 0 END) as MediCalBnp,
   (CASE WHEN Q.CaseNoteTypeID = 8 and Q.CaseNoteTypeReasonID in (13, 14, 15) THEN 1 ELSE 0 END) as SsiSubmission,
   (CASE WHEN Q.CaseNoteTypeID = 8 and Q.CaseNoteTypeReasonID in (19, 20, 21, 22, 23, 24, 25, 26, 27)  THEN 1 ELSE 0 END) as SSIBnp,
   (CASE WHEN Q.CaseNoteTypeID = 10 and Q.CaseNoteTypeReasonID = 28  THEN 1 ELSE 0 END) as VaSubmission,
   (CASE WHEN Q.CaseNoteTypeID = 10 and Q.CaseNoteTypeReasonID in (30, 31, 32, 33)  THEN 1 ELSE 0 END) as VABnp,
   (CASE WHEN Q.CaseNoteTypeID = 16 THEN 1 ELSE 0 END) as SignedCid, Q.UserID
 FROM 
 (SELECT EpisodeID, CaseNoteTypeID, CaseNoteTypeReasonID, EventDate, UserID FROM 
  (SELECT EpisodeID, CaseNoteTypeID, CaseNoteTypeReasonID, EventDate, UserID,
    ROW_NUMBER() OVER(PARTITION BY EpisodeID, CaseNoteTraceID ORDER BY CaseNoteID DESC) AS RowNum FROM CASENOTE 
	Where EventDate > = DateAdd(YEAR, -1, @FromDAte) AND EventDate <=@ToDate 
	AND ActionStatus != 10) d  WHERE d.RowNum = 1) Q 
	GROUP BY Q.EpisodeID, Q.CaseNoteTypeID, Q.CASENoteTYPEreasonID, Q.EventDate, Q.UserID) R GROUP BY R.EpisodeID, R.UserID) J on T.EpisodeID = J.EpisodeID AND T.BenefitWorkerID =  J.UserID

Update  T SET T.ApplicationDate = t1.ApplicationDate, T.MediCalDiscrepancy = t1.MediCalDiscrepancy, T.SSIDiscrepancy = t1.SSIDiscrepancy,
  T.VADiscrepancy= t1.VADiscrepancy, T.CIDDiscrepancy = t1.CIDDiscrepancy
  FROM @tempCollection T INNER JOIN
  (SELECT EpisodeID,
   (CASE WHEN MaxMedicalDate IS NOT NULL THEN MaxMedicalDate 
         WHEN MaxSsiDate IS NOT NULL THEN MaxSsiDate
	     WHEN MaxVaDate IS NOT NULL THEN MaxVaDate ELSE NULL END)ApplicationDate,
 (CASE WHEN (ISNULL(HIVPos, 0) = 1 AND CidDelivered IS NULL) OR (ISNULL(HIVPos, 0) = 0 AND CidDelivered IS NOT NULL) THEN 1 ELSE 0 END) AS CIDDiscrepancy,
 (CASE WHEN ISNULL(TotalServicesNotProvided, 0) > 0 or TotalMediCalBnp > 0 THEN 1 ELSE 
	       (CASE WHEN ISNULL(TotalMediCalApps, 0) <> ISNULL(TotalMSubmission, 0) THEN 1 ELSE 
		     (CASE WHEN MaxMediCalDate IS NULL AND ISNULL(TotalMediCalSubmission, 0) > 0 THEN 1 
			       WHEN MaxMediCalDate IS NULL AND ISNULL(MediCalCode, '') <> '' THEN 1
				   ELSE 0 END) END) END) MediCalDiscrepancy,
 (CASE WHEN TotalServicesNotProvided > 0 OR TotalSSIBnp > 0 THEN 1 ELSE 
	       (CASE WHEN ISNULL(TotalSsiApps, 0) <> ISNULL(TotalSSubmission, 0) THEN 1 ELSE 
		     (CASE WHEN MaxSsiDate IS NULL AND ISNULL(TotalSsiSubmission, 0) > 0 THEN 1 
			       WHEN MaxSsiDate IS NULL AND ISNULL(SSICode, '') <> '' THEN 1
				   ELSE 0 END) END) END) SsiDiscrepancy,
(CASE WHEN TotalServicesNotProvided > 0 or TotalVABnp > 0 THEN 1 ELSE 
	       (CASE WHEN ISNULL(TotalVaApps, 0) <> ISNULL(TotalVSubmission, 0) THEN 1 ELSE 
		     (CASE WHEN MaxVaDate IS NULL AND ISNULL(TotalVaSubmission, 0) > 0 THEN 1 
			       WHEN MaxVaDate IS NULL AND ISNULL(VACode, '') <> '' THEN 1
				   ELSE 0 END) END) END) VaDiscrepancy
 FROM @tempCollection) t1  on T.EpisodeID  = t1.EpisodeID
 --select * from #tempCollection
 -- get report requested data
 select EpisodeID, (CASE WHEN ISNULL(ReleaseDate, '') = '' THEN '' ELSE convert(varchar(10), ReleaseDate, 110) END)EPRD, 
 County, ReleaseTo, MediCalFa, SSIFa, VAFa, BenefitWorkerId, BenefitWorkerName, CDCRNum, 
 (CASE WHEN ISNULL(ScreeningDate, '') = '' THEN  '' ELSE convert(varchar(10), ScreeningDate, 110) END)ScreeningDate, 
 MediCalDate, SsiDate, VaDate, 
 ISNULL(CentralFileReview, 0)CentralFileReview, ISNULL(CaseManagement,0)CaseManagement,
 ISNULL(ExitInterview,0)ExitInterview, ISNULL(FaceToFace, 0)FaceToFace,
 ISNULL(MedicalFileReview, 0)MedicalFileReview, ISNULL(StatusCheckOrUpdate, 0)StatusCheckOrUpdate, 
 ISNULL(MediCalSubmission, 0)MediCalSubmission, ISNULL(ServicesNotProvided, 0)ServicesNotProvided, 
 ISNULL(ServicesNotProvidedRefused, 0)ServicesNotProvidedRefused,
 ISNULL(ServicesNotProvidedOther,0)ServicesNotProvidedOther, ISNULL(SsiSubmission, 0)SsiSubmission,
 ISNULL(VaSubmission, 0)VaSubmission,ISNULL(CaseAssigned, 0)CaseAssigned, ISNULL(TcmpChrono, 0)TcmpChrono,
 ISNULL(OutcomeLetterCount, 0)OutcomeLetterCount, 
 (CASE WHEN ISNULL(OutcomeLetter, '')='' THEN '' ELSE convert(varchar(10), OutcomeLetter, 110) END)OutcomeLetter,
 ISNULL(CidCreated, 0)CidCreated, ISNULL(CidDeliveredCount, 0)CidDeliveredCount,
 (CASE WHEN ISNULL(CidDelivered, '')='' THEN '' ELSE convert(varchar(10), CidDelivered, 110) END)CidDelivered,   
 (CASE WHEN ISNULL(TelInterview, '')='' THEN '' ELSE convert(varchar(10), TelInterview, 110) END)TelInterview,	
 (CASE WHEN ISNULL(ExtInterview, '')='' THEN '' ELSE convert(varchar(10), ExtInterview, 110) END)ExtInterview,	
 ISNULL(MediCalCode, '')MediCalCode, ISNULL(SSICode, '')SSICode, ISNULL(VACode, '')VACode, 
 ISNULL(MediCalBnp, 0)MediCalBnp, ISNULL(SSIBnp, 0)SSIBnp, ISNULL(VABnp, 0)VABnp,
 CIDDiscrepancy, MediCalDiscrepancy, SsiDiscrepancy, VaDiscrepancy, 
 (CASE WHEN ApplicationDate IS NOT NULL THEN convert(varchar(7), ApplicationDate, 126) ELSE '' END) AppDate
 from @tempCollection
END
GO
GRANT EXECUTE ON [dbo].[spRptProductivityV3] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
/*================================================================
   Create procedure spGetCaseNotes
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetCaseNotes]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetCaseNotes]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetCaseNotes]
  @EpisodeID int,
  @CurrentUserID int,
  @SearchStr nvarchar(20) ='',
  @CaseNoteTraceID int  = 0
 AS	
BEGIN
   
	 /*notes should be edit/delete within 90 days after created (instead of original:"close of next business day").
	   Users should be able to edit notes for ANY inmate regardless of case assignment
	   (as long as they are created by the same author) */
  DECLARE @CanEditAllCases bit 
  DECLARE @CanAccessReports bit

  SELECT @CanAccessReports = CanAccessReports, @CanEditAllCases = CanEditAllCases 
	  FROM [User] WHERE UserID  = @CurrentUserID
  IF @CaseNoteTraceID = 0
	SELECT t1.CaseNoteID, t1.CaseNoteTraceID, t1.CaseNoteTypeID, t2.Name AS CaseNoteType, 
	       t1.CaseNoteTypeReasonID, t1.UserID, t3.Name AS CaseNoteTypeReason,t1.EventDate,
	       t1.CreatedDateTime AS CreateDate, t1.[Text], (SELECT Name FROM [dbo].[fn_GetUserName](t1.UserID))CreatedBy,
		   --(t4.LastName + ', ' + t4.Firstname + ' ' + ISNULl(t4.Middlename, ''))  
		   t1.ActionStatus, 
		   (CASE WHEN DateDIFF(day, t1.CreatedDateTime, GetDate()) <= 90 AND 
		              (@CanEditAllCases = 1 OR @CanAccessReports = 1 OR t1.UserID = @CurrentUserID)
		    THEN 1 ELSE 0 END)NoteCanEdit 
	  FROM (SELECT CaseNoteID, CaseNoteTraceID,CaseNoteTypeID, CaseNoteTypeReasonID,  
	               UserID,EventDate,CreatedDateTime,ActionStatus,[Text],
	              ROW_NUMBER() OVER(PARTITION BY CaseNoteTraceID ORDER BY CaseNoteID DESC) as RowNum 
			 FROM dbo.CaseNote WHERE EpisodeID  = @EpisodeID) t1 
		  INNER JOIN dbo.CaseNoteType t2 ON t1.CaseNoteTypeID = t2.CaseNoteTypeID
	      LEFT OUTER JOIN dbo.CaseNoteTypeReason t3 ON t1.CaseNoteTypeReasonID = t3.CaseNoteTypeReasonID
	 WHERE t1.RowNum = 1 AND (1=(CASE WHEN @SearchStr = 'ALL' THEN 1 ELSE 0 END) OR (@SearchStr <> 'ALL' AND ISNULl(t1.ActionStatus, 0) <> 10))
  ELSE
    SELECT t1.CaseNoteID, t1.CaseNoteTraceID, t1.CaseNoteTypeID, t2.Name AS CaseNoteType, 
	       t1.CaseNoteTypeReasonID, t1.UserID, t3.Name AS CaseNoteTypeReason,t1.EventDate,
	       t1.CreatedDateTime AS CreateDate, t1.[Text], 
		   (SELECT Name FROM [dbo].[fn_GetUserName](t1.UserID))CreatedBy,  
		   t1.ActionStatus, 0 AS NoteCanEdit 
	  FROM (SELECT CaseNoteID, CaseNoteTraceID,CaseNoteTypeID, CaseNoteTypeReasonID,  
	               UserID,EventDate,CreatedDateTime,ActionStatus,[Text]
			 FROM dbo.CaseNote WHERE EpisodeID  = @EpisodeID AND CaseNoteTraceID = @CaseNoteTraceID) t1 
		  INNER JOIN dbo.CaseNoteType t2 ON t1.CaseNoteTypeID = t2.CaseNoteTypeID
	      LEFT OUTER JOIN dbo.CaseNoteTypeReason t3 ON t1.CaseNoteTypeReasonID = t3.CaseNoteTypeReasonID
		  --INNER JOIN dbo.[User] t4 ON t1.UserID = t4.UserID	                    
End

GO
GRANT EXECUTE ON [dbo].[spGetCaseNotes] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

/*================================================================
   Create index IX_LatestEpisode in Episode.LatestEpisode
==================================================================*/
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name='IX_LatestEpisode' AND object_id = OBJECT_ID('Episode'))
BEGIN
CREATE NONCLUSTERED INDEX [IX_LatestEpisode] ON [dbo].[Episode]
(
	[LatestEpisode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END
GO
/*================================================================
  Create index IX_LatestAssignment in CaseAssignment.LatestAssignment
==================================================================*/
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name='IX_LatestAssignment' AND object_id = OBJECT_ID('CaseAssignment'))
BEGIN
CREATE NONCLUSTERED INDEX [IX_LatestAssignment] ON [dbo].[CaseAssignment]
(
	[LatestAssignment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END
GO

/*================================================================
   Update Episode to have LatestEpisode flagged
   **Update the LatestEpisode flagged in import SP
==================================================================*/
UPDATE tgr SET  LatestEpisode = 1 FROM
Episode tgr INNER JOIN
(SELECT EpisodeID, ROW_NUMBER() OVER(PARTITION BY e.OffenderID ORDER BY EpisodeID DESC) AS rownum  
   FROM Episode e INNER JOIN Offender o on e.OffenderID  = o.offenderID )scr on scr.EpisodeID  =  tgr.EpisodeID
 Where scr.rownum = 1

/*================================================================
   Update CaseAssignment to have LatestAssignment flagged
==================================================================*/
UPDATE tgr SET  LatestAssignment = 1 FROM
CaseAssignment tgr INNER JOIN
(SELECT CaseAssignmentID FROM
(SELECT CaseAssignmentID, EpisodeID, ROW_NUMBER() OVER(PARTITION BY EpisodeID ORDER BY CaseAssignmentID DESC) AS rownum  
   FROM CaseAssignment)D Where D.rownum = 1)scr on scr.CaseAssignmentID  =  tgr.CaseAssignmentID
      
/*================================================================
   Add a new User for IRP
==================================================================*/
IF NOT EXISTS(SELECT  * FROM [User] WHERE UserID  = 1)
BEGIN
SET IDENTITY_INSERT [User] OFF
INSERT INTO [dbo].[User]([userID],[UserName],[FirstName],[LastName],[IsActive]
           ,[IsBenefitWorker],[LoginFailures],[CanEditAllCases],[CanEditAllNotes],[CanAccessReports]
           ,[CaseNoteHidden],[EmailComfirmed],[IsADUser],[ViewBenefitOnly],[DocumentHidden])
   VALUES ( 1,'tcmpAdmin','BASS','ADMIN',1,0,0,0,0,0,0,0,1,0,0)   
SET IDENTITY_INSERT [User] ON
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*================================================================
   Create procedure spImportSomsRecord
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spImportSomsRecord]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spImportSomsRecord]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Carol
-- Create date: 4/12/2017
-- Description:	Import Soms Data
-- =============================================
CREATE PROCEDURE [dbo].[spImportSomsRecord] 
	@SomsOffenderId int = 0 ,
	@SomsUploadId int = 0,
	@ResultMessage nvarchar(max) output
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	
	Declare @RowCount nvarchar(30)
	
	IF @SomsUploadId = 0 
	  SET @SomsUploadId = (SELECT MAX(SomsUploadID) from [BassWeb].dbo.SomsUpload)
	
	Declare @NewCDCR int = (select CounT(s.cdcnumber) from [BassWeb].dbo.SomsRecord s left outer join episode e 
          on s.cdcnumber = e.cdcrnum where s.somsuploadid = @SomsUploadId and e.cdcrnum is null )

    IF @NewCDCR = 0 
	   SET @ResultMessage = 'No new cdcr found.'
	ELSE
	   SET @ResultMessage = Convert(varchar(5), @NewCDCR) + ' new cdcr found.'

	--Update Episode set InitialImportDate = ReferralDate where InitialImportDate is null
	--DECLARE @ResultMessage nvarchar(2000)
	--1. Offender
	DECLARE @SsiDeterminString nvarchar(200) ='DPW,DPO,DPM,DNM,DPH,DPS,DPV,DKD,DD1,DD2,DD3,DSH,ICF,APU,MHC,EOP,ACU'
	Update Offender Set LastName = d.InmateLastName, FirstName = d.InmateFirstName,DOB = d.InmateDateOfBirth,
		   GenderID = (SELECT GenderID FROM Gender Where Code = IsNULL(d.InmateSexCode, 'U') ), 
		   SSN = (CASE WHEN SSN in ('999-99-9999', '111-11-1111', '', null) THEN ISNULL(d.SSNum, '999-99-9999') ELSE
		   SSN END) , PC290 = (CASE WHEN len(ISNULL(PENALCODE, '')) > 0 THEN 1 ELSE 0 END),
		   PhysDisabled=(CASE WHEN d.DPPHearingCode <> '' or d.DPPMobilityCode <> '' or d.DPPSpeechCode <> '' or d.DPPVisionCode <> '' THEN 1 ELSE 0 END),
		   EOP = (CASE WHEN CHARINDEX('EOP', d.MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END), CCCMS  = (CASE WHEN CHARINDEX('CCCMS', d.MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END),
		   DevDisabled = (CASE WHEN d.DevelopDisabledEvaluation in ('DD1', 'DD2', 'DD3') THEN 1 ELSE 0 END ), 
		   MedPlacement=(CASE WHEN d.DPPHearingCode = 'DPH' OR d.DPPMobilityCode in ('DPM', 'DPO', 'DPW') OR d.DPPSpeechCode = 'DPS' OR d.DPPVisionCode = 'DPV'  THEN 1
			 ELSE 0 END ), SSI=(CASE WHEN (CHARINDEX(d.DPPMobilityCode, @SsiDeterminString) > 0  OR  
										  CHARINDEX(d.DPPHearingCode, @SsiDeterminString) > 0  OR
										  CHARINDEX(d.DPPSpeechCode, @SsiDeterminString) > 0  OR
										  CHARINDEX(d.DPPVisionCode, @SsiDeterminString) > 0  OR
										  CHARINDEX(d.DevelopDisabledEvaluation, @SsiDeterminString) > 0  OR
										  CHARINDEX('EOP', d.MentalHealthTreatmentNeeded) > 0) AND d.DevelopDisabledEvaluation <> 'NCF' THEN 1 ELSE 0 END),
		    SomsUploadID = @SomsUploadId
		   From Offender,  
	(Select e.EpisodeID,e.ReleaseDate, e.CDCRNum, e.CustodyFacilityID, s.CDCNumber,o.OffenderID, o.PID,s.CellBed, s.CurrentIncarcBeginDate, s.DevelopDisabledEvaluation, 
		   ISNULL(s.DPPHearingCode, '') as DPPHearingCode, ISNULL(s.DPPMobilityCode, '') AS DPPMobilityCode, 
		   ISNULL(s.DPPSpeechCode, '') AS DPPSpeechCode, ISNULL(s.DPPVisionCode, '') as DPPVisionCode, s.FileDate, s.InmateDateOfBirth,
		   s.Loc, s.InmateFirstName, s.InmateLastName,s.InmateSexCode, ScheduledReleaseDate, ISNULL(s.Lifer, '') AS Lifter, s.MentalHealthTreatmentNeeded, 
		   s.PAROLEUNIT, s.PAROLEAGENTFIRSTNAME,s.PAROLEAGENTLASTNAME, s.PAROLEAGENTMIDDLENAME, s.PrimaryBedUse, s.PENALCODE,
		   s.SomsUploadID, s.SSNum, s.Unit from Episode e Inner join Offender o on e.OffenderID = o.OffenderID 
		   inner join  [BassWeb].dbo.SomsRecord s on s.SomsOffenderID = o.PID and s.CDCNumber =  e.CDCRNum
	Where s.SomsUploadID = @SomsUploadId ) as d Where Offender.OffenderID = d.OffenderID 
	SET @RowCount = convert(nvarchar(30),@@ROWCOUNT)
	IF @@ROWCOUNT = 0  
	 SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Warning: No rows were updated in Offender table.'; 
	ELSE 
	  SET @ResultMessage = @ResultMessage + char(13) + char(10) + @RowCount + ' rows have been updated in Offender table.'; 
	
	-- unassign cases based on facility changed
	Update CaseAssignment Set UnAssignedDateTime = GetDate() where EpisodeID in 
	(Select e.EpisodeID from Episode e Inner join Offender o on e.OffenderID = o.OffenderID 
		   inner join  [BassWeb].dbo.SomsRecord s on s.SomsOffenderID = o.PID and s.CDCNumber =  e.CDCRNum
	Where s.SomsUploadID = @SomsUploadId and e.CustodyFacilityID <> (CASE WHEN s.Unit = 'PRCCF' OR s.Unit ='PUCCF' THEN 
	    (select TOP 1 FacilityID from Facility where OrgCommonID = s.Unit and Disabled <> 1 and 
			substring(SomsLoc, CHARINDEX( '-', SomsLoc)+1, len(SomsLoc)) = substring(s.Loc, CHARINDEX( '-', s.Loc)+1, len(s.Loc)))
        ELSE (select TOP 1 FacilityID from Facility where OrgCommonID = s.Unit and Disabled <> 1) END)) 

	--Do update for all mapped records on episode and Offender 
	--2. EpisodeReferralDate < DateAdd(year, 1, GetDate())
	Update Episode Set ReferralDate = (CASE WHEN Episode.ReleaseDate <> d.ScheduledReleaseDate and  Episode.ReferralDate < DateAdd(year, -1, GetDate()) Then GetDate() 
											ELSE Episode.ReferralDate END),
		   ReleaseDate = (Case WHEN d.ReviewStatus = 0 THEN d.ScheduledReleaseDate ELSE Episode.ReleaseDate END ),
		   ReleaseCountyID = (CASE WHEN ISNULL(d.CountyOfRelease, '') <> '' AND EXISTS(SELECT 1 FROM County WHERE Name =d.CountyOfRelease) THEN (SELECT CountyID FROM County WHERE Name =d.CountyOfRelease ) ELSE NULL END ),  
		   FileDate = d.FileDate, Housing = d.CellBed, Lifer = (CASE WHEN d.Lifer ='Y' THEN 1 ELSE 0 END),
		   SomsReleaseDate=(CASE WHEN SomsReleaseDate is not null THEN SomsReleaseDate ELSE d.ScheduledReleaseDate END),
		   CustodyFacilityID = (CASE WHEN d.Unit = 'PRCCF' OR d.Unit ='PUCCF' THEN 
		                          (select TOP 1 FacilityID from Facility where OrgCommonID = d.Unit and Disabled <> 1 and 
								  substring(SomsLoc, CHARINDEX( '-', SomsLoc)+1, len(SomsLoc)) = substring(d.Loc, CHARINDEX( '-', d.Loc)+1, len(d.Loc)))
                                     ELSE (select TOP 1 FacilityID from Facility where OrgCommonID = d.Unit and Disabled <> 1) END),
		   ParoleUnit = d.PAROLEUNIT, ParoleAgent = (CASE WHEN d.PAROLEAGENTLASTNAME is NOT null AND d.PAROLEAGENTLASTNAME <> '' THEN
			 d.PAROLEAGENTLASTNAME +  ', ' + ISNULL(d.PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(d.PAROLEAGENTMIDDLENAME, '')
			   ELSE ISNULL(d.PAROLEAGENTFIRSTNAME, '') + ' ' + ISNULL(d.PAROLEAGENTMIDDLENAME, '') END), SomsUploadID = @SomsUploadId
		   From Episode,  
	(Select e.EpisodeID,e.ReleaseDate, e.CDCRNum, s.CDCNumber,o.OffenderID, o.PID,o.ReviewStatus, s.CellBed, 
	       s.CurrentIncarcBeginDate, s.DevelopDisabledEvaluation, s.MentalHealthTreatmentNeeded, s.CountyOfRelease,
		   s.DPPHearingCode, s.DPPMobilityCode, s.DPPSpeechCode, s.DPPVisionCode, s.FileDate, s.InmateDateOfBirth,
		   s.Loc, s.InmateFirstName, s.InmateLastName,s.InmateSexCode, ScheduledReleaseDate, ISNULL(s.Lifer, '') AS Lifer,  
		   s.PAROLEUNIT, s.PAROLEAGENTFIRSTNAME,s.PAROLEAGENTLASTNAME, s.PAROLEAGENTMIDDLENAME, s.PrimaryBedUse,
		   s.SomsUploadID, s.SSNum, s.Unit from Episode e Inner join Offender o on e.OffenderID = o.OffenderID 
		   inner join  [BassWeb].dbo.SomsRecord s on s.SomsOffenderID = o.PID and s.CDCNumber =  e.CDCRNum
	Where s.SomsUploadID = @SomsUploadId ) as d Where Episode.EpisodeID = d.EpisodeID 
	SET @RowCount = convert(nvarchar(30),@@ROWCOUNT)
	IF @@ROWCOUNT = 0  
	 SET @ResultMessage = @ResultMessage +  char(13) + char(10) + 'Warning: No rows were updated in Episode Table.'; 
	ELSE 
	  SET @ResultMessage = @ResultMessage +  char(13) + char(10) + @RowCount + ' rows have been updated in Episode Table.'; 

	-- unassign cases based on release date
	Update CaseAssignment Set  UnAssignedDateTime = GetDate() Where EpisodeID in (
	(Select EpisodeID from Episode where ReleaseDate  < GetDate())) AND UnAssignedDateTime is null

	--ADD new Offender AND Episode
	INSERT INTO Offender (ReviewStatus, FirstName, LastName, GenderID, SSN, DOB, EOP, CCCMS, PhysDisabled,DevDisabled,
		MedPlacement, SSI, PID, PC290, PC457, USVet, LongTermMedCare, Hospice, AssistedLiving, HIVPos,
		ChronicIllness, Elderly, DSH, VRSS, InitialImportDate, SomsUploadId)
		SELECT 0, InmateFirstName, InmateLastName, (select GenderID from Gender where Code= InmateSexCode), ISNULL(SSNum, ''), 
		InmateDateOfBirth, (CASE WHEN CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END), 
		(CASE WHEN CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END),
		(CASE WHEN DPPHearingCode <> '' or DPPMobilityCode <> '' or DPPSpeechCode <> '' or DPPVisionCode <> '' THEN 1 ELSE 0 END),
		(CASE WHEN DevelopDisabledEvaluation in ('DD1', 'DD2', 'DD3') THEN 1 ELSE 0 END ),  
		(CASE WHEN DPPHearingCode = 'DPH' OR DPPMobilityCode in ('DPM', 'DPO', 'DPW') OR DPPSpeechCode = 'DPS' OR 
		           DPPVisionCode = 'DPV'  THEN 1 ELSE 0 END ),		
		(CASE WHEN CHARINDEX(DPPMobilityCode, @SsiDeterminString) > 0  OR  
					CHARINDEX(DPPHearingCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPSpeechCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DPPVisionCode, @SsiDeterminString) > 0  OR
					CHARINDEX(DevelopDisabledEvaluation, @SsiDeterminString) > 0  OR
					CHARINDEX('EOP', MentalHealthTreatmentNeeded) > 0  OR
					CHARINDEX('CCCMS', MentalHealthTreatmentNeeded) > 0 THEN 1 ELSE 0 END),
		s.SomsOffenderID, (CASE WHEN len(ISNULL(s.PENALCODE, '')) >0 THEN 1 ELSE 0 END)
		,0,0,0,0,0,0,0,0,0,0, GetDate(), @SomsUploadId
		FROM [BassWeb].dbo.SomsRecord s left Outer join dbo.Offender o on s.SomsOffenderID = o.PID 
		where s.somsuploadId = @SomsUploadId and o.PID is null 
		SET @RowCount = convert(nvarchar(30),@@ROWCOUNT)	
		IF @@ROWCOUNT = 0  
		SET @ResultMessage = @ResultMessage +  char(13) + char(10) +   ' No new PID add to Offender table.'; 
	ELSE 
		SET @ResultMessage = @ResultMessage + char(13) + char(10) + @RowCount + ' pid have been added into Offender table.';
		
	
	-- Insert new episode
	INSERT INTO Episode (OffenderID, ReleaseDate, ParoleUnit, ReleaseCountyID,  ParoleAgent, CDCRNum, ReferralDate,
		FileDate, Housing, Lifer,SomsReleaseDate,AuthToRepresent,ReleaseOfInfoSigned, ApplyForSSI,ApplyForVA,
		ApplyForMediCal, _Hold_Disabled, InitialImportDate,CustodyFacilityID, SomsUploadId)
       SELECT o.OffenderID, s.ScheduledReleaseDate, s.PAROLEUNIT,
		(CASE WHEN ISNULl(CountyOfRelease, '') <> '' AND EXISTS(select 1 from County where Name =CountyOfRelease) THEN 
			         (select CountyID from County where Name =CountyOfRelease) ELSE NULL END),				 
		(CASE WHEN  ISNULl(PAROLEAGENTLASTNAME, '') = '' THEN  ISNULl(PAROLEAGENTFIRSTNAME,'') + ' ' + ISNULl(PAROLEAGENTMIDDLENAME,'')
			ELSE ISNULl(PAROLEAGENTLASTNAME, '')  + ', ' + ISNULl(PAROLEAGENTFIRSTNAME,'') + ' ' + ISNULl(PAROLEAGENTMIDDLENAME,'') END ),
		s.CDCNumber, s.FileDate, s.FileDate, ISNULL(CellBed, ''), (CASE WHEN s.Lifer ='Y' THEN 1 ELSE 0 END), 
		ScheduledReleaseDate,0,0,0,0,0,0, GetDate(),
		(CASE WHEN s.Unit = 'PRCCF' OR s.Unit ='PUCCF' THEN 
			(select TOP 1 FacilityID from Facility where OrgCommonID = s.Unit and Disabled <> 1 and SomsLoc = s.Loc )
			  ELSE (select TOP 1 FacilityID from Facility where OrgCommonID = s.Unit and Disabled <> 1 ) END), @SomsUploadId
		FROM [BassWeb].dbo.SomsRecord s Left Outer Join Episode e on s.CDCNumber = e.CDCRNum
			inner join Offender o on s.SomsOffenderID = o.PID
		where s.somsuploadId = @SomsUploadId and e.CDCRNum is null
		SET @RowCount = convert(nvarchar(30),@@ROWCOUNT)	
		IF @@ROWCOUNT = 0  
		SET @ResultMessage = @ResultMessage +  char(13) + char(10) +   ' No new CDCR Number add to Episode table.'; 
	ELSE 
		SET @ResultMessage = @ResultMessage + char(13) + char(10) + @RowCount + ' CDCR Number have been added into episode table.';
	
	--Update MhStatus in Episode
	Update Episode Set MhStatus = D.MhStatus FROM
    (Select e.EpisodeID, e.CDCRNum, 
     CONCAT((CASE WHEN ISNULL(s.[DPPHearingCode], '') = '' THEN '' ELSE s.[DPPHearingCode] + ',' END), 
             (CASE WHEN ISNULL(s.[DPPMobilityCode], '') = '' THEN '' ELSE s.[DPPMobilityCode] + ',' END),
			 (CASE WHEN ISNULL(s.[DPPSpeechCode], '') = '' THEN '' ELSE s.[DPPSpeechCode] + ',' END),  
             (CASE WHEN ISNULL(s.[DPPVisionCode], '') = '' THEN '' ELSE s.[DPPVisionCode] + ',' END),
			 (CASE WHEN ISNULL(s.[DevelopDisabledEvaluation], '') = '' THEN '' ELSE s.[DevelopDisabledEvaluation] + ',' END),
			 (CASE WHEN ISNULL(s.[MentalHealthTreatmentNeeded], '') = '' THEN '' ELSE 
			 RTRIM(substring(s.[MentalHealthTreatmentNeeded], 1, CHARINDEX('-',s.[MentalHealthTreatmentNeeded])-1)) END)) As MhStatus
   FROM Episode e Inner Join  SomsRecord s on e.CDCRNum = s.CDCNumber 
   where s.somsUploadID = @SomsUploadId) D Where Episode.EpisodeID =  D.EpisodeID	 

   --reset LatestEpisode 
   UPDATE tgr SET  LatestEpisode = null FROM Episode

   UPDATE tgr SET  LatestEpisode = 1 FROM Episode tgr INNER JOIN
     (SELECT EpisodeID, ROW_NUMBER() OVER(PARTITION BY e.OffenderID ORDER BY EpisodeID DESC) AS rownum  
        FROM Episode e INNER JOIN Offender o on e.OffenderID  = o.offenderID )scr on scr.EpisodeID  =  tgr.EpisodeID
       Where scr.rownum = 1

	DECLARE @ret varchar(max)
	--check missing PID
	IF EXISTS(select s.cdcnumber, s.somsoffenderid from [BassWeb].dbo.SomsRecord s left outer join offender e 
         on s.somsoffenderId = e.pid where s.somsuploadid = @SomsUploadId and e.pid is null)
	BEGIN
	   SET @ret = (select'['+
		stuff(
		 ( select ',{ "CDCR": "' + tb.cdcnumber + '", "PID": "' + convert(varchar, tb.somsoffenderid)
		  +'"}' from (select s.cdcnumber, s.somsoffenderid from [BassWeb].dbo.SomsRecord s left outer join offender e 
		on s.somsoffenderId = e.pid where s.somsuploadid = @SomsUploadId and e.pid is null ) tb  for XML Path('')
		 ),1,1,'' ) +']')
       SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Looking into DB for the following missing PID:'
	   SET @ResultMessage = @ResultMessage + char(13) + char(10) + @ret
 	END 

	--check missing CDCR
	IF EXISTS(select s.cdcnumber, s.somsoffenderid from [BassWeb].dbo.SomsRecord s left outer join episode e 
                  on s.cdcnumber = e.cdcrnum where s.somsuploadid = @SomsUploadId and e.cdcrnum is null)
	BEGIN
	   SET @ret = (select'['+
		stuff(
		 ( select ',{ "CDCR": "' + tb.cdcnumber + '", "PID": "' + convert(varchar, tb.somsoffenderid)
		  +'"}' from (select s.cdcnumber, s.somsoffenderid from [BassWeb].dbo.SomsRecord s left outer join episode e 
                  on s.cdcnumber = e.cdcrnum where s.somsuploadid = @SomsUploadId and e.cdcrnum is null) tb  for XML Path('')
		 ),1,1,'' ) +']')
	  SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Looking into DB for the following missing CDCR:'
      SET @ResultMessage = @ResultMessage + char(13) + char(10) + @ret
 	END 
	--check duplicate PID
	IF EXISTS(select OffenderID, PID from 
	(select OffenderID, PID, ROW_NUMBER() OVER(PARTITION BY PID ORDER BY OffenderID DESC) as RowNum from Offender ) d
	where d.RowNum > 1 AND d.PID > 0)
	BEGIN
	SET @ret = (select'['+
		stuff(
		 ( select ',{ "OffenderID": "' + convert(varchar, tb.OffenderID) + '", "PID": "' + convert(varchar, tb.PID)
		  +'"}' from (select OffenderID, PID from 
	(select OffenderID, PID, ROW_NUMBER() OVER(PARTITION BY PID ORDER BY OffenderID DESC) as RowNum from Offender ) d
	where d.RowNum > 1 AND d.PID > 0) tb  for XML Path('')
		 ),1,1,'' ) +']')
		select @ret
	  SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Looking into DB for the following duplicated PID:'
      SET @ResultMessage = @ResultMessage + char(13) + char(10) + @ret
	END

	--check duplicate CDCR
	IF EXISTS(select OffenderID, CDCRNum from 
	(select OffenderID, CDCRNum, ROW_NUMBER() OVER(PARTITION BY CDCRNum ORDER BY EpisodeID DESC) as RowNum from Episode ) d
	where d.RowNum > 1)
	BEGIN
	SET @ret = (select'['+
		stuff(
		 ( select ',{ "OffenderID": "' + convert(varchar, tb.OffenderID) + '", "CDCR": "' + tb.CDCRNum
		  +'"}' from (select OffenderID, CDCRNum from 
	(select OffenderID, CDCRNum, ROW_NUMBER() OVER(PARTITION BY CDCRNum ORDER BY EpisodeID DESC) as RowNum from Episode ) d
	where d.RowNum > 1) tb  for XML Path('')
		 ),1,1,'' ) +']')
		select @ret
	  SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Looking into DB for the following duplicated CDCR:'
      SET @ResultMessage = @ResultMessage + char(13) + char(10) + @ret
	END

	SET @ResultMessage = @ResultMessage + char(13) + char(10) + 'Import Completed.'
End
GO
GRANT EXECUTE ON [dbo].[spGetCaseNotes] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

/*================================================================
   1. Add a new column to PATS CaseIRP table
   2. Create procedure spGetPATSEpisodeIRPToBASS in PATSWEB
==================================================================*/
USE [PATSWebV2Test]
GO

/*================================================================
 Add new column of CaseIRP
==================================================================*/
IF COL_LENGTH('CaseIRP','BassUserID') IS NULL
BEGIN
   ALTER TABLE CaseIRP
   ADD BassUserID bit null
END
GO
/*===============================================================
   Create procedure spGetPATSEpisodeIRPToBASS
==================================================================*/
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spGetPATSEpisodeIRPToBASS]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spGetPATSEpisodeIRPToBASS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: 2020-03-08
-- Update date: 
-- Description:	Retrive IRP From PATS to BASS
-- =============================================
CREATE PROCEDURE [dbo].[spGetPATSEpisodeIRPToBASS]
    @CDCRNum varchar(6) = '',
	@IRPID int = 0
AS	
BEGIN
   DECLARE @True bit = 1
   DECLARE @False bit =0
   DECLARE @PATSEpisodeID int  = 0
   DECLARE @BassUserID int  = 0 
   DECLARE @PatsUserID int =0
   DECLARE @PatsUserName varchar(70) = ''
   IF @CDCRNum <> '' AND Exists(SELECT EpisodeID FROM Episode WHERE CDCRNum = @CDCRNum)
    BEGIN
	  SET @PATSEpisodeID = (SELECT EpisodeID FROM Episode WHERE CDCRNum = @CDCRNum)	
	  IF EXISTS(SELECT IRPID FROM dbo.EpisodeTrace WHERE EpisodeID  = @PATSEpisodeID AND ISNULL(IRPID, 0) <> 0 ) 	     
        SELECT @BassUserID = ISNULL(BassUserID, 0), @PatsUserID = ActionBy FROM dbo.CaseIRP WHERE ID = (SELECT IRPID FROM dbo.EpisodeTrace WHERE EpisodeID  = @PATSEpisodeID )
	  IF @BassUserID = 0 AND  @PATSEpisodeID <> 1379
		  SET @PatsUserName = (SELECT Name FROM [dbo].[fn_GetUserName]( @PatsUserID))
	  EXEC [dbo].[spGetEpisodeIRP] @PATSEpisodeID, @IRPID
	END
	ELSE
	  BEGIN	     
         SELECT 0 AS IRPID, NeedID, NULL AS NeedStatus, 
            @False AS NeedStatus1,
		    @False AS NeedStatus2,
		    @False AS NeedStatus3,
		    @False AS NeedStatus4,
		    Name AS Need, '' AS DescriptionCurrentNeed, '' AS ShortTermGoal, '' AS LongTermGoal,
            @False AS LongTermStatusMet, @False AS LongTermStatusNoMet,
		    NULL AS LongTermStatusDate, NULL AS PlanedIntervention, '' AS Note, '' as IDTTDecision, @True AS IsLastIRPSet, 1 AS ActionStatus, 
		    '' AS ActionName, GetDate() AS DateAction
         FROM [dbo].[tlkpCaseNeeds] Order By NeedID
	  END
	
   SELECT @PATSEpisodeID AS PATSEpisodeID,  @PatsUserName AS PatsUserName, @BassUserID AS BassUserID
END
GO
GRANT EXECUTE ON [dbo].[spGetPATSEpisodeIRPToBASS] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
GRANT EXECUTE ON [dbo].[spGetPATSEpisodeIRPToBASS] to [ACCOUNTS\Svc_CDCRPATSUser]
GO 