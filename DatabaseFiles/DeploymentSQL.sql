/* Create new two tables for Episode Offender data changes*/
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
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[sp_GetAllApplications]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[sp_GetAllApplications]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[sp_GetAllApplications] 
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
         UPDATE dbo.CaseAssignment SET LatestAssignment = null WJERE EpisodeID  = @EpisodeID
         INSERT INTO [dbo].[CaseAssignment]([EpisodeID],[BenefitWorkerID],[AssignedDateTime],[ActionBy], LatestAssignment)
            VALUES ( @EpisodeID ,@BenefitWorkerID,GetDate(), @CurrentUserID, 1)
    END
	exec [dbo].[spGetInmateProfile] @EpisodeID, @CurrentUserID, 1
END

GO

GRANT EXECUTE ON [dbo].[spSaveAssignment] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO
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
IF EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'[dbo].[spTeamWorkLocationList]') AND OBJECTPROPERTY(id, N'IsProcedure')=1)
  DROP PROCEDURE [dbo].[spTeamWorkLocationList]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




EXECUTE the following SPs:
sp_GetAllApplications
spGetApplicationEpisodesDropdownList
spCaseAssignmentsV3
spSaveArchivedApp
spSaveAssignment
spGetApplications
spGetBassStaffName
spGetBenefitWorkerAssignedCaseV3
spGetEpisodeDropDownListV3
spGetInmateProfile
spGetSearchingList
spGetUploadedFiles
spGetUserAndTeamAppsWorked
spGetUserAndTeamCasesWorked
spGetUserAppsWorked
spGetUserByUsername
spTeamWorkLocationList
spGetApplicationByType
spRptBWProductivityV3
spRptProductivityV3
spGetCaseNotes
spGetPATSEpisodeIRPToBASS  -- In pats db

/*Create index*/
CREATE NONCLUSTERED INDEX [IX_LatestEpisode] ON [dbo].[Episode]
(
	[LatestEpisode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

/*Update Episode to have latest episode flagged*/
UPDATE tgr SET  LatestEpisode = 1 FROM
Episode tgr INNER JOIN
(SELECT EpisodeID, ROW_NUMBER() OVER(PARTITION BY e.OffenderID ORDER BY EpisodeID DESC) AS rownum  
   FROM Episode e INNER JOIN Offender o on e.OffenderID  = o.offenderID )scr on scr.EpisodeID  =  tgr.EpisodeID
 Where scr.rownum = 1

UPDATE tgr SET  LatestAssignment = 1 FROM
CaseAssignment tgr INNER JOIN
(SELECT CaseAssignmentID FROM
(SELECT CaseAssignmentID, EpisodeID, ROW_NUMBER() OVER(PARTITION BY EpisodeID ORDER BY CaseAssignmentID DESC) AS rownum  
   FROM CaseAssignment)D Where D.rownum = 1)scr on scr.CaseAssignmentID  =  tgr.CaseAssignmentID
      
/*Update the samething above in import*/

/*Add a new column to PATS CaseIRP table*/
ALTER TABLE [dbo].[CaseIRP]
ADD [BassUserID] int null
GO

/*Add a new User for IRP*/
SET IDENTITY_INSERT [User] OFF
INSERT INTO [dbo].[User]([userID],[UserName],[FirstName],[LastName],[IsActive]
           ,[IsBenefitWorker],[LoginFailures],[CanEditAllCases],[CanEditAllNotes],[CanAccessReports]
           ,[CaseNoteHidden],[EmailComfirmed],[IsADUser],[ViewBenefitOnly],[DocumentHidden])
   VALUES ( 1,'tcmpAdmin','BASS','ADMIN',1,0,0,0,0,0,0,0,1,0,0)   
SET IDENTITY_INSERT [User] ON
GO

/*Add new column of Episode*/
ALTER TABLE Episode
ADD LatestEpisode bit null
GO

/*Add new column of CaseAssignment*/
ALTER TABLE CaseAssignment
ADD LatestAssignment bit null
GO