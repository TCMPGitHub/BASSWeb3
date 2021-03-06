USE [BassWebTest]
GO
/****** Object:  StoredProcedure [dbo].[spTeamWorkLocationList]    Script Date: 11/7/2021 6:25:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----drop PROCEDURE [dbo].[spTeamWorkLocationList]

CREATE PROCEDURE [dbo].[spTeamWorkLocationList]
    @StartDate DateTime,
	@EndDate DateTime,
	@UserID int = 0
AS	
BEGIN
    SELECT t1.UserID, t1.PageLoadId, t1.IpAddress, (t1.Action + ' at : ' + ISNULL(t2.LocationAbbr, ISNULl(t1.IpAddress, 'Unknown')))Title,
	'Team meneber location' Description, Convert(datetime, t1.DateTimeOffset) as Start, DateAdd(hour, 1, Convert(datetime, t1.DateTimeOffset)) as [End]
  from PageLoad t1 left outer join [tlkpIpAddressMap] t2 on substring(t1.IpAddress,1, len(t2.IpAddress)-1) 
   = substring(t2.IpAddress,1, len(t2.IpAddress)-1) Where t1.UserID  = @UserID and t1.Method = 'POST' AND
   t1.DateTimeOffset >= @StartDate AND t1.DateTimeOffset <=@EndDate 
END 
GO
GRANT EXECUTE ON [dbo].[spTeamWorkLocationList] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO