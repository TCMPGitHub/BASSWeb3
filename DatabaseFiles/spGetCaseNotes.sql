USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetCaseNotes]    Script Date: 7/29/2021 7:01:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetCaseNotes]

CREATE PROCEDURE [dbo].[spGetCaseNotes]
  @EpisodeID int,
  @CurrentUserID int,
  @SearchStr nvarchar(20) ='',
  @CaseNoteTraceID int  = 0
 AS	
BEGIN
   
	 /*notes should be edit/delete within 90 days after created (instead of original:"close of next business day").
	   Users should be able to edit notes for ANY inmate regardless of case assignment
	   (as long as they are created by the same author) */
  DECLARE @CanEditAllCases bit 
  DECLARE @CanAccessReports bit

  SELECT @CanAccessReports = CanAccessReports, @CanEditAllCases = CanEditAllCases 
	  FROM [User] WHERE UserID  = @CurrentUserID
  IF @CaseNoteTraceID = 0
	SELECT t1.CaseNoteID, t1.CaseNoteTraceID, t1.CaseNoteTypeID, t2.Name AS CaseNoteType, 
	       t1.CaseNoteTypeReasonID, t1.UserID, t3.Name AS CaseNoteTypeReason,t1.EventDate,
	       t1.CreatedDateTime AS CreateDate, t1.[Text], (SELECT Name FROM [dbo].[fn_GetUserName](t1.UserID))CreatedBy,
		   --(t4.LastName + ', ' + t4.Firstname + ' ' + ISNULl(t4.Middlename, ''))  
		   t1.ActionStatus, 
		   (CASE WHEN DateDIFF(day, t1.CreatedDateTime, GetDate()) <= 90 AND 
		              (@CanEditAllCases = 1 OR @CanAccessReports = 1 OR t1.UserID = @CurrentUserID)
		    THEN 1 ELSE 0 END)NoteCanEdit 
	  FROM (SELECT CaseNoteID, CaseNoteTraceID,CaseNoteTypeID, CaseNoteTypeReasonID,  
	               UserID,EventDate,CreatedDateTime,ActionStatus,[Text],
	              ROW_NUMBER() OVER(PARTITION BY CaseNoteTraceID ORDER BY CaseNoteID DESC) as RowNum 
			 FROM dbo.CaseNote WHERE EpisodeID  = @EpisodeID) t1 
		  INNER JOIN dbo.CaseNoteType t2 ON t1.CaseNoteTypeID = t2.CaseNoteTypeID
	      LEFT OUTER JOIN dbo.CaseNoteTypeReason t3 ON t1.CaseNoteTypeReasonID = t3.CaseNoteTypeReasonID
	 WHERE t1.RowNum = 1 AND (1=(CASE WHEN @SearchStr = 'ALL' THEN 1 ELSE 0 END) OR (@SearchStr <> 'ALL' AND ISNULl(t1.ActionStatus, 0) <> 10))
  ELSE
    SELECT t1.CaseNoteID, t1.CaseNoteTraceID, t1.CaseNoteTypeID, t2.Name AS CaseNoteType, 
	       t1.CaseNoteTypeReasonID, t1.UserID, t3.Name AS CaseNoteTypeReason,t1.EventDate,
	       t1.CreatedDateTime AS CreateDate, t1.[Text], 
		   (SELECT Name FROM [dbo].[fn_GetUserName](t1.UserID))CreatedBy,  
		   t1.ActionStatus, 0 AS NoteCanEdit 
	  FROM (SELECT CaseNoteID, CaseNoteTraceID,CaseNoteTypeID, CaseNoteTypeReasonID,  
	               UserID,EventDate,CreatedDateTime,ActionStatus,[Text]
			 FROM dbo.CaseNote WHERE EpisodeID  = @EpisodeID AND CaseNoteTraceID = @CaseNoteTraceID) t1 
		  INNER JOIN dbo.CaseNoteType t2 ON t1.CaseNoteTypeID = t2.CaseNoteTypeID
	      LEFT OUTER JOIN dbo.CaseNoteTypeReason t3 ON t1.CaseNoteTypeReasonID = t3.CaseNoteTypeReasonID
		  --INNER JOIN dbo.[User] t4 ON t1.UserID = t4.UserID	                    
End

GO

GRANT EXECUTE ON [dbo].[spGetCaseNotes] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO

