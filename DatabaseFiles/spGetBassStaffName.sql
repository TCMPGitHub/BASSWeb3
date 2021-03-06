USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetBassStaffName]    Script Date: 11/6/2021 8:49:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spGetBassStaffName]

CREATE PROCEDURE [dbo].[spGetBassStaffName]
  @UserID int
 AS	
BEGIN
    SELECT (LastName + ', ' + FirstName + ISNULl(MiddleName, ''))UserName FROM dbo.[User] WHERE IsActive = 1 AND UserID  = @UserID 
END
GO

GRANT EXECUTE ON [dbo].[spGetBassStaffName] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO