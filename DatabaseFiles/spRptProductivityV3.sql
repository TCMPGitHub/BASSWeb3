USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spRptProductivityV3]    Script Date: 11/10/2021 8:21:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[spRptProductivityV3]
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