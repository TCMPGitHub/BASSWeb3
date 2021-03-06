USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetApplicationEpisodesDropdownList]    Script Date: 11/6/2021 8:32:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[spGetApplicationEpisodesDropdownList]
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