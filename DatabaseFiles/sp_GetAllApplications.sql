USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetAllApplications]    Script Date: 1/22/2019 8:42:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
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

