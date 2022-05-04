/* Create new two tables for Episode Offender data changes*/
CREATE TABLE dbo.EpisodeOffender(
        ID int NOT NULL IDENTITY (1, 1) primary key,
        EpisodeID int not null, 
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
CREATE NONCLUSTERED INDEX [IX_EpisodeID] ON [dbo].[EpisodeOffender]
(
	[EpisodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
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

/*Add a new column to PATS CaseIRP table*/
ALTER TABLE [dbo].[CaseIRP]
ADD [BassUserID] int null

/*Add a new User for IRP*/
SET IDENTITY_INSERT [User] OFF
INSERT INTO [dbo].[User]([userID],[UserName],[FirstName],[LastName],[IsActive]
           ,[IsBenefitWorker],[LoginFailures],[CanEditAllCases],[CanEditAllNotes],[CanAccessReports]
           ,[CaseNoteHidden],[EmailComfirmed],[IsADUser],[ViewBenefitOnly],[DocumentHidden])
   VALUES ( 1,'tcmpAdmin','BASS','ADMIN',1,0,0,0,0,0,0,0,1,0,0)   
SET IDENTITY_INSERT [User] ON

/*Add new column of Episode*/
ALTER TABLE Episode
ADD LatestEpisode bit null

/*Add new column of CaseAssignment*/
ALTER TABLE CaseAssignment
ADD LatestAssignment bit null

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


