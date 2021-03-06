USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetEpisodeDropDownListV3]    Script Date: 11/6/2021 8:56:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetEpisodeDropDownListV3]

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