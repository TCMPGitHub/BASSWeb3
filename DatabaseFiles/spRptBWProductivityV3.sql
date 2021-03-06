USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spRptBWProductivityV3]    Script Date: 11/7/2021 6:20:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop PROCEDURE [dbo].[spRptBWProductivityV3]
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