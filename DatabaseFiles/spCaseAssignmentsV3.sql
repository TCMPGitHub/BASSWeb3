USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spCaseAssignmentsV3]    Script Date: 8/10/2017 9:44:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Drop Procedure [spCaseAssignmentsV3]
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
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
