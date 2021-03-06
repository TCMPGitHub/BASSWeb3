USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spGetUserByUsername]    Script Date: 11/7/2021 6:19:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE [dbo].[spGetUserByUsername]
CREATE PROCEDURE [dbo].[spGetUserByUsername]
	-- Add the parameters for the stored procedure here
	@Username nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [User] WHERE Username = @Username
END
GO
GRANT EXECUTE ON [dbo].[spGetUserByUsername] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO