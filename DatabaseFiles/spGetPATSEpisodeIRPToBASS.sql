USE [PATSWebV2Test]
GO
/****** Object:  StoredProcedure [dbo].[spGetPATSEpisodeIRPToBASS]    Script Date: 11/6/2021 7:55:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: 2020-03-08
-- Update date: 
-- Description:	Retrive IRP From PATS to BASS
-- =============================================
--DROP PROCEDURE [dbo].[spGetPATSEpisodeIRPToBASS]
CREATE PROCEDURE [dbo].[spGetPATSEpisodeIRPToBASS]
    @CDCRNum varchar(6) = '',
	@IRPID int = 0
AS	
BEGIN
   DECLARE @True bit = 1
   DECLARE @False bit =0
   DECLARE @PATSEpisodeID int  = 0
   DECLARE @BassUserID int  = 0
   IF @CDCRNum <> '' AND Exists(SELECT EpisodeID FROM Episode WHERE CDCRNum = @CDCRNum)
    BEGIN
	  SET @PATSEpisodeID = (SELECT EpisodeID FROM Episode WHERE CDCRNum = @CDCRNum)	
	  IF EXISTS(SELECT IRPID FROM dbo.EpisodeTrace WHERE EpisodeID  = @PATSEpisodeID AND ISNULL(IRPID, 0) <> 0 ) 
	      SET @BassUserID = (SELECT ISNULL(BassUserID, 0) FROM dbo.CaseIRP WHERE ID = (SELECT IRPID FROM dbo.EpisodeTrace WHERE EpisodeID  = @PATSEpisodeID ))
	  EXEC [dbo].[spGetEpisodeIRP] @PATSEpisodeID, @IRPID
	END
	ELSE
	  BEGIN	     
         SELECT 0 AS IRPID, NeedID, NULL AS NeedStatus, 
            @False AS NeedStatus1,
		    @False AS NeedStatus2,
		    @False AS NeedStatus3,
		    @False AS NeedStatus4,
		    Name AS Need, '' AS DescriptionCurrentNeed, '' AS ShortTermGoal, '' AS LongTermGoal,
            @False AS LongTermStatusMet, @False AS LongTermStatusNoMet,
		    NULL AS LongTermStatusDate, NULL AS PlanedIntervention, '' AS Note, '' as IDTTDecision, @True AS IsLastIRPSet, 1 AS ActionStatus, 
		    '' AS ActionName, GetDate() AS DateAction
         FROM [dbo].[tlkpCaseNeeds] Order By NeedID
	  END
	
   SELECT @PATSEpisodeID AS PATSEpisodeID, @BassUserID AS BassUserID
END
GO
GRANT EXECUTE ON [dbo].[spGetPATSEpisodeIRPToBASS] to [ACCOUNTS\Svc_CDCRBASSSQLWte]
GO 
GRANT EXECUTE ON [dbo].[spGetPATSEpisodeIRPToBASS] to [ACCOUNTS\Svc_CDCRPATSUser]
GO 


--ALTER TABLE [dbo].[CaseIRP]
--ADD [BassUserID] int null