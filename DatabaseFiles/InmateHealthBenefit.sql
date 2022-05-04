USE [BassWeb]
GO

/****** Object:  View [dbo].[InmateHealthBenefit]    Script Date: 11/29/2021 12:09:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[InmateHealthBenefit]
AS
SELECT   t1.ApplicationID, t1.ApplicationTypeID, t1.EpisodeID, t2.CDCRNum, t2.ClientName,
                    (SELECT   Name
                    FROM       dbo.County
                    WHERE    (CountyID = ISNULL(t2.ReleaseCountyID, 0))) AS ReleaseCountyName, (CASE WHEN t2.EOP = 1 THEN 'EOP' WHEN t2.CCCMS = 1 THEN 'CCCMS' ELSE '' END) AS MHStatus, t1.AgreesToApply, t1.AppliedOrRefusedOnDate, 
                (CASE WHEN PhoneInterviewDate = NULL THEN '' ELSE CONVERT(varchar(10), PhoneInterviewDate, 101) END) AS PhoneInterviewDate, (CASE WHEN OutcomeDate = NULL THEN '' ELSE CONVERT(varchar(10), OutcomeDate, 101) END) 
                AS OutcomeDate, (CASE WHEN ISNULL(ApplicationOutcomeID, - 1) < 0 AND AgreesToApply = 0 AND AppliedOrRefusedOnDate IS NOT NULL THEN 'Refused' WHEN ISNULL(ApplicationOutcomeID, - 1) < 0 AND 
                AgreesToApply = 1 THEN 'Pending' ELSE
                    (SELECT   NAME
                    FROM       ApplicationOutCome
                    WHERE    ApplicationOutcomeID = t1.ApplicationOutcomeID) END) AS OutCome,
                    (SELECT   Name
                    FROM       dbo.ApplicationType
                    WHERE    (ApplicationTypeID = t1.ApplicationTypeID)) AS ApplicationTypeName, (CASE WHEN ArchivedOnDate = NULL THEN '' ELSE CONVERT(varchar(10), ArchivedOnDate, 101) END) AS ArchivedOnDate, t1.BICNum, 
                (CASE WHEN IssuedOnDate = NULL THEN '' ELSE CONVERT(varchar(10), IssuedOnDate, 101) END) AS IssuedOnDate, t2.EpisodeID AS Expr1
FROM       dbo.Application AS t1 INNER JOIN
                    (SELECT   e.EpisodeID, o.EOP, o.CCCMS, e.CDCRNum, e.ReleaseCountyID, o.LastName + ',' + o.FirstName + ' ' + ISNULL(o.MiddleName, '') AS ClientName
                    FROM       dbo.Episode AS e INNER JOIN
                                     dbo.Offender AS o ON e.OffenderID = o.OffenderID) AS t2 ON t1.EpisodeID = t2.EpisodeID
WHERE    (t1.AppliedOrRefusedOnDate >= DATEADD(Year, - 1, GETDATE()))

GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InmateHealthBenefit'
GO

