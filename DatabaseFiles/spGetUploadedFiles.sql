USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetUploadedFiles]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetUploadedFiles]

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

