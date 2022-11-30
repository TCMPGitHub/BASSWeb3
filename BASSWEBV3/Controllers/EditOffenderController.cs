using BassIdentityManagement.DAL;
using BassIdentityManagement.Data;
using BassIdentityManagement.Entities;
using BassWebV3.ViewModels;
using Kendo.Mvc.Extensions;
using Kendo.Mvc.UI;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using static BassWebV3.DataAccess.BassConstants;

namespace BassWebV3.Controllers
{
    [RoutePrefix("EditOffender")]
    public class EditOffenderController : AbstractBassController
    {
        [DataContract]
        public class ChunkMetaData
        {
            [DataMember(Name = "uploadUid")]
            public string UploadUid { get; set; }
            [DataMember(Name = "fileName")]
            public string FileName { get; set; }
            [DataMember(Name = "relativePath")]
            public string RelativePath { get; set; }
            [DataMember(Name = "contentType")]
            public string ContentType { get; set; }
            [DataMember(Name = "chunkIndex")]
            public long ChunkIndex { get; set; }
            [DataMember(Name = "totalChunks")]
            public long TotalChunks { get; set; }
            [DataMember(Name = "totalFileSize")]
            public long TotalFileSize { get; set; }
        }
        public class FileResult
        {
            public bool uploaded { get; set; }
            public string fileUid { get; set; }
        }
        [Route]
        [HttpGet]
        // GET: EditOffender
        public ActionResult Index()
        {
            ViewBag.ControllerID = ControllerID.EditOffender;
            if (CurrentUser == null && (ApplicationUser)Session["CurrentUser"] == null)
            {
                return RedirectToAction("Login", "BASSAccount");
            }
            else if(CurrentUser == null && (ApplicationUser)Session["CurrentUser"] != null)
            { 
              ViewBag.CurrentUser = (ApplicationUser)Session["CurrentUser"];
            }
            ViewBag.IsAppViewOnly = CurrentUser.ViewBenefitOnly;
            try
            {
                UserController.RecordPageLoad(CurrentUser.UserID, RouteData.Values["Controller"].ToString(), RouteData.Values["action"].ToString(),
                    HttpContext.Request.HttpMethod, IpAddress);
            }
            catch (Exception err)
            {
                return PartialView("Error", new HandleErrorInfo(err, RouteData.Values["Controller"].ToString(), RouteData.Values["action"].ToString()));
            }

            if (ViewBag.IsAppViewOnly)
                return RedirectToAction("ViewAppOnly");
            else
            {
                List<ParameterInfo> param = new List<ParameterInfo>()
                {
                     new ParameterInfo { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID }
                };
                List<string> objlist = new List<string>();
                objlist.Add("ActiveUsers");
                objlist.Add("Facilities");
                objlist.Add("CaseNoteTypes");
                objlist.Add("Episode");
                var result = SqlHelper.GetMultiRecordsets<object>("spGetSearchingList", param, objlist, 1).ToList();
                return View(new OffenderSearch
                {
                    AllSearchUsers = ((List<ActiveUserList>)result[0]).ToList(),
                    AllSearchFacilities = ((List<Facility>)result[1]).ToList(),
                    LoginUser = CurrentUser,
                    SelectEpisode = (LoadedEpisode)result[3]
                });
            }

        }
        [Route("~/ViewApplication")]
        [HttpGet]
        public ActionResult ViewAppOnly()
        {
            ViewBag.ControllerID = ControllerID.EditOffender;
            ViewBag.CurrentUser = (ApplicationUser)Session["CurrentUser"];
            ViewBag.IsAppViewOnly = CurrentUser.ViewBenefitOnly;

            return View( new OffenderApplicationViewOnly { ReleaseCountyID = -1 });
        }
        public JsonResult GetAllApplicationSearchResults(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return Json(null, JsonRequestBehavior.AllowGet);
            }

            var result = GetApplicationSearchResults(text, 0);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public JsonResult GetAllOffenderEpisodes(int EpisodeID)
        {
            var result = GetApplicationSearchResults(string.Empty, EpisodeID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public ActionResult GetBWAssignment(int? BenefitWorkerID)
        {
            ApplicationUser user = CurrentUser;
            if (BenefitWorkerID == null)
            {
                BenefitWorkerID = CurrentUser.UserID;
            }
            else
            {
                if (BenefitWorkerID != user.UserID)
                {
                    var query = string.Format("SELECT * FROM dbo.[User] WHERE UserID ={0}", BenefitWorkerID);
                    user = SqlHelper.ExecuteCommands<ApplicationUser>(query, 1).FirstOrDefault();
                }
            }

            return PartialView("_MyAssignments", new UserAssignment
            {
                UserId = user.UserID,
                IsBenifitWorker = user.IsBenefitWorker
            });
        }
        public ActionResult GetOffenderDetails(int EpisodeID)
        {
            //get latest soms data
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            parameters.Add(new ParameterInfo() { ParameterName = "All", ParameterValue = 0 });
            //get object list
            List<string> objlist = new List<string>();
            objlist.Add("DerivedSomsData");
            objlist.Add("InmateProfileData");
            objlist.Add("Episodes");
            objlist.Add("Counties");
            objlist.Add("Facilities");
            objlist.Add("Genders");
            objlist.Add("EpisodeAcpDshTypes");
            objlist.Add("EpisodeMdoSvpTypes");
            objlist.Add("EpisodeMedReleaseTypes");
            objlist.Add("Destinations");
            objlist.Add("SomsReleaseDates");
            var results = SqlHelper.GetInmateDetails<object>("spGetInmateProfile", parameters, objlist);
            var episodes = ((List<Episodes>)results[2]).ToList();
            var allf = ((List<Facility>)results[4]).ToList();
            InmateProfileData profile = (InmateProfileData)results[1];
            var isLatest = (episodes.Where(w => w.EpisodeID == EpisodeID).FirstOrDefault().ReferralDate).IndexOf('*') > 0 ? true : false;
            var Editingable = isLatest && HasEditPermission(CurrentUser, profile.BenefitWorkerID);
            OffenderData offender = new OffenderData
            {
                EditingEnabled = Editingable,
                DerivedSomsData = (DerivedSomsData)results[0],
                Inmate = profile,
                AllEpisodes = episodes,
                AllCounties = ((List<County>)results[3]).ToList(),
                AllFacilities = allf,
                AllGenders = ((List<Gender>)results[5]).ToList(),
                AllAcpDshTypes = ((List<EpisodeAcpDshType>)results[6]).ToList(),
                AllMdoSvpTypes = ((List<EpisodeMdoSvpType>)results[7]).ToList(),
                AllMedReleaseTypes = ((List<EpisodeMedReleaseType>)results[8]).ToList(),
                AllDestinationIDs = ((List<LookUpTable>)results[9]).ToList(),
                SomsReleaseDates = ((List<ReleaseDateChanged>)results[10]).ToList()
            };

            return PartialView("_OffenderData", offender);
        }
        //public ActionResult GetPATSIRP(string CDCRNum, int IRPID)
        //{
        //    if (CDCRNum == "") return null;
        //    var results = GetBHRIRPData(CDCRNum,0, IRPID);
        //    //JavaScriptSerializer serializer = new JavaScriptSerializer();
        //    ////==================================================================
        //    //BHRIRPData irp = (BHRIRPData)results[0];
        //    //irp.IRPList = serializer.Deserialize<List<BHRIRP>>(irp.BHRIRPJson);

        //    //var actuser = string.Empty;
        //    //var objAdditionInfo = (BHRIRPAdditionInfo)results[3];
        //    //if (objAdditionInfo.BASSUserID > 0)
        //    //{
        //    //    actuser = GetBassUserName(objAdditionInfo.BASSUserID);
        //    //}
        //    //else
        //    //{
        //    //    if (string.IsNullOrEmpty(objAdditionInfo.PATSUserName))
        //    //    {
        //    //        actuser = CurrentUser.UserLFI();
        //    //    }
        //    //    else
        //    //        actuser = objAdditionInfo.PATSUserName;
        //    //}
        //    return PartialView("_BHRIRP", results);
        //}
        public ActionResult OffenderBenefitRead([DataSourceRequest] DataSourceRequest request, int EpisodeID, int ApplicationTypeID, int CountyID)
        {
            List<ApplicationReadonly> benefitapp = GetLatestBenefitApp(EpisodeID, ApplicationTypeID, CountyID);
            return Json(benefitapp.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        public ActionResult HierarchyBinding_Application([DataSourceRequest] DataSourceRequest request, int EpisodeID, int ApplicationTypeID)
        {
          var query = string.Format(@"SELECT [ApplicationID], t1.[ApplicationTypeID], [AgreesToApply], [EpisodeID], 
                (CASE WHEN ISNULl(t1.ApplicationOutcomeID, 0) = 0 THEN 'Pending' ELSE t3.Name END)Outcome,
                ISNULl([OutcomeDate], '')OutcomeDate,ISNULl([IssuedOnDate], '')IssuedOnDate,[BICNum],
                [AppliedOrRefusedOnDate], ISNULL([ArchivedOnDate], '')ArchivedOnDate, ISNULL([PhoneInterviewDate], '')PhoneInterviewDate
           FROM [dbo].[Application] t1 LEFT OUTER JOIN[dbo].[ApplicationOutcome] t3 ON t1.ApplicationOutcomeID = t3.ApplicationOutcomeID
          WHERE EpisodeID = @EpisodeID = {0} AND ApplicationTypeID = {1}", EpisodeID, ApplicationTypeID);
            var benefitList = SqlHelper.ExecuteCommands<ApplicationReadonly>(query, 1);
            return Json(benefitList.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult SaveAssignCase(int EpisodeID, int BenefitWorkerID)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>()
            {
                new ParameterInfo { ParameterName = "EpisodeID", ParameterValue = EpisodeID },
                new ParameterInfo { ParameterName = "BenefitWorkerID", ParameterValue = BenefitWorkerID },
                new ParameterInfo { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID }
            };
            //get object list
            List<string> objlist = new List<string>();
            objlist.Add("DerivedSomsData");
            objlist.Add("InmateProfileData");
            objlist.Add("Episodes");
            objlist.Add("Counties");
            objlist.Add("Facilities");
            objlist.Add("Genders");
            objlist.Add("EpisodeAcpDshTypes");
            objlist.Add("EpisodeMdoSvpTypes");
            objlist.Add("EpisodeMedReleaseTypes");
            objlist.Add("Destinations");
            objlist.Add("ApplicationFlags");
            var results = SqlHelper.GetInmateDetails<object>("spSaveAssignment", parameters, objlist);
            DerivedSomsData SomsData = (DerivedSomsData)results[0];
            InmateProfileData profile = (InmateProfileData)results[1];
            var episodes = ((List<Episodes>)results[2]).ToList();
            var allf = ((List<Facility>)results[4]).ToList();
            var isLatest = (episodes.Where(w => w.EpisodeID == EpisodeID).FirstOrDefault().ReferralDate).IndexOf('*') > 0 ? true : false;
            var Editingable = isLatest && HasEditPermission(CurrentUser, profile.BenefitWorkerID);
            OffenderData offender = new OffenderData
            {
                EditingEnabled = Editingable,
                IsUnassignedCase = string.IsNullOrEmpty(profile.BenefitWorkerName) && isLatest && CurrentUser.IsBenefitWorker,
                DerivedSomsData = (DerivedSomsData)results[0],
                Inmate = profile,
                AllEpisodes = episodes,
                AllCounties = ((List<County>)results[3]).ToList(),
                AllFacilities = allf,
                AllGenders = ((List<Gender>)results[5]).ToList(),
                AllAcpDshTypes = ((List<EpisodeAcpDshType>)results[6]).ToList(),
                AllMdoSvpTypes = ((List<EpisodeMdoSvpType>)results[7]).ToList(),
                AllMedReleaseTypes = ((List<EpisodeMedReleaseType>)results[8]).ToList(),
                AllDestinationIDs = ((List<LookUpTable>)results[9]).ToList()
                //SomsReleaseDates = ((List<ReleaseDateChanged>)results[10]).ToList()
            };
            Applications apps = new Applications
            {
                //AllOutcomes = ((List<OutcomeType>)results[10]).ToList(),
                //AppData = ((List<ApplicationData>)results[12]).ToList(),
                AppFlags = (ApplicationFlags)results[10],
                CanEditApplication = Editingable,
                //AllFacilities = allf,
                User = CurrentUser
            };

            CaseNoteFiles casenf = new CaseNoteFiles
            {
                CanEditNote = Editingable || CurrentUser.CanEditAllNotes,
                EpisodeID = EpisodeID,
                HideCaseNote = CurrentUser.CaseNoteHidden,
                HideDocument = CurrentUser.DocumentHidden,
                CanUploadFile = Editingable || CurrentUser.CanEditAllCases
            };

            return PartialView("_InmatePanel", new InmateData
            {
                ShowCaseNoteList = CurrentUser.CanAccessReports,
                Offender = offender,
                Appliations = apps,
                CaseNF = casenf,
                EpisodeID = EpisodeID
            });
            //return PartialView("_OffenderData", new OffenderData
            //{
            //    EditingEnabled = isLatest && HasEditPermission(CurrentUser, profile.BenefitWorkerID),
            //    DerivedSomsData = SomsData,
            //    Inmate = profile,
            //    AllEpisodes = episodes,
            //    AllCounties = ((List<County>)results[3]).ToList(),
            //    AllFacilities = ((List<Facility>)results[4]).ToList(),
            //    AllGenders = ((List<Gender>)results[5]).ToList(),
            //    AllAcpDshTypes = ((List<EpisodeAcpDshType>)results[6]).ToList(),
            //    AllMdoSvpTypes = ((List<EpisodeMdoSvpType>)results[7]).ToList(),
            //    AllMedReleaseTypes = ((List<EpisodeMedReleaseType>)results[8]).ToList(),
            //    AllDestinationIDs = ((List<LookUpTable>)results[9]).ToList()
            //});
        }
        public JsonResult GetAllCounties()
        {
            var query = "Select CountyID, Name FROM County";
            var result = SqlHelper.ExecuteCommands<County>(query, 1).OrderBy(o => o.Name);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        private List<SelectListItem> GetApplicationSearchResults(string SearchString, int EpisodeID)
        {
            List<ParameterInfo> parms = new List<ParameterInfo>
            {
                new ParameterInfo {  ParameterName= "SearchString", ParameterValue = SearchString },
                new ParameterInfo {  ParameterName= "EpisodeID", ParameterValue = EpisodeID }
            };               
            return SqlHelper.GetRecords<SelectListItem>("spGetApplicationEpisodesDropdownList", parms);
        }
        private List<ApplicationReadonly> GetLatestBenefitApp(int EpisodeID, int ApplicationTypeID, int CountyID)
        {
            List<ParameterInfo> parms = new List<ParameterInfo>
            {
                new ParameterInfo {  ParameterName= "EpisodeID", ParameterValue = EpisodeID },
                new ParameterInfo {  ParameterName= "ApplicationTypeID", ParameterValue = ApplicationTypeID },
                new ParameterInfo {  ParameterName= "CountyID", ParameterValue = CountyID }
            };
            return SqlHelper.GetRecords<ApplicationReadonly>("sp_GetAllApplications", parms);
        }
        public ActionResult GetIRP(string CDCRNum, int EpisodeID, int IRPID)
        {
            if (CDCRNum == "" && EpisodeID == 0) return null;
            var results = GetBHRIRPData(CDCRNum, EpisodeID, IRPID);
            
            return PartialView("_BHRIRP", results);
        }
        private BHRIRPViewModel GetBHRIRPData(string CDCRNum, int EpisodeID, int IRPID)
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            List<ParameterInfo> parms = new List<ParameterInfo> {
                { new ParameterInfo {  ParameterName= "CDCRNum", ParameterValue = CDCRNum }},
                { new ParameterInfo {  ParameterName= "EpisodeID", ParameterValue = EpisodeID }},
                { new ParameterInfo {  ParameterName= "IRPID", ParameterValue = IRPID }},
                { new ParameterInfo {  ParameterName= "CurrentUserID", ParameterValue = CurrentUser.UserID }} };
            List<string> objlist = new List<string>();
            objlist.Add("BHRIRP");
            objlist.Add("IdentifiedBarriersToIntervention");
            objlist.Add("BarrierFrequency");
            objlist.Add("BHRIRPAdditionInfo");
            var results = SqlHelper.GetMultiRecordsets<object>("spGetPATSEpisodeIRPToBASS", parms, objlist, 0);            
            //==================================================================
            BHRIRPData irp = (BHRIRPData)results[0];
            irp.IRPList = serializer.Deserialize<List<BHRIRP>>(irp.BHRIRPJson);

            var actuser = string.Empty;
            var objAdditionInfo = (BHRIRPAdditionInfo)results[3];
            if (objAdditionInfo.BASSUserID > 0)
            {
                actuser = GetBassUserName(objAdditionInfo.BASSUserID);
            }
            else
            {
                if (string.IsNullOrEmpty(objAdditionInfo.PATSUserName))
                {
                    actuser = CurrentUser.UserLFI();
                }
                else
                    actuser = objAdditionInfo.PATSUserName;
            }
            return new BHRIRPViewModel {
                ActionUserName = actuser,
                BarrFreqList = (List<BarrierFrequency>)results[2],
                IBTIList = (List<IdentifiedBarriersToIntervention>)results[1],
                IRP = irp,
                CanEdit = CurrentUser.CanAccessReports || CurrentUser.IsBenefitWorker
            };
        }
        public JsonResult GetBHRIRPDateList(int EpisodeID)
        {
            var query = string.Format("DECLARE @EpisodeID int = {0} " +
                "DECLARE @ID int = (SELECT ISNULl(BHRIRPID, 0) FROM EpisodeTrace WHERE EpisodeID = @EpisodeID) " +
                "IF @ID = 0 " +
                "SELECT 0 AS IRPID, (CONVERT(NVARCHAR(15), GetDate(), 110) + '*') AS IRPDate " +
                "ELSE " +
                  " SELECT IRPID, (CONVERT(NVARCHAR(15), DateAction, 110) + " +
                  " (CASE WHEN IRPID = @ID THEN '*' ELSE '' END)) as IRPDate " +
                  " From dbo.CaseBHRIRP Where EpisodeID = @EpisodeID AND ActionStatus <> 10 ORDER BY DateAction DESC", EpisodeID);
            var dates = SqlHelper.ExecuteCommands<BHRIRPDates>(query, 0);
            return Json(dates, JsonRequestBehavior.AllowGet);
        }
        public ActionResult SaveBHRIRP(BHRIRPViewModel casrIrp)
        {
            if (ModelState.IsValid)
            {
                var newid = SaveBIRP(casrIrp.IRP, casrIrp.IRP.EpisodeID);
                var result = GetBHRIRPData("", casrIrp.IRP.EpisodeID, newid);
                return PartialView("_BHRIRP", result);
            }
            return null; // ErrorsJson(ModelStateErrors());
        }
        private int SaveBIRP(BHRIRPData IRPs, int EpisodeID)
        {
            if (IRPs == null || IRPs.IRPList.Count() == 0)
                return 0;

            //var currentDateTime = DateTime.Now;
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            var irp = serializer.Serialize(IRPs.IRPList);
            var isnew = IRPs.IRPId == 0 ? 1 : 2;
            var query = string.Format(@"DECLARE @ID int = 0 INSERT INTO [dbo].[CaseBHRIRP]([EpisodeID],[CurrentPhaseStatus],[BHRIRPJson],[AdditionalRemarks]
           ,[ActionStatus],[ActionBy],[DateAction],[BassUserID]) VALUES({0},{1},{2},{3},{4},1379,GetDate(),{5}) SET @ID=@@IDENTITY
           UPDATE dbo.EpisodeTrace SET BHRIRPID=@ID WHERE EpisodeID={0} SELECT @ID",
           IRPs.EpisodeID, IRPs.CurrentPhaseStatus.HasValue ? IRPs.CurrentPhaseStatus.ToString() : "null", "'" + RemoveUnprintableChars(irp) + "'",
           string.IsNullOrEmpty(IRPs.AdditionalRemarks) ? "null" : "'" + RemoveUnprintableChars(IRPs.AdditionalRemarks) + "'", isnew, CurrentUser.UserID);
            return SqlHelper.ExecuteQueryWithReturnValue(query, 0);
        }
        //public ActionResult SaveIRP(IRP caseIRPs)
        //{
        //    if (caseIRPs == null || caseIRPs.IRPSetList.Count() == 0)
        //        return null;

        //    //var currentDateTime = DateTime.Now;
        //    var query = string.Format(@"DECLARE @EpisodeID int = {0} DECLARE @IsNew int = 0 DECLARE @IRpDate DateTime = GetDate() " +
        //        "DECLARE @ID int = (SELECT ISNULl(IRPID,0) FROM dbo.EpisodeTrace WHERE EpisodeID = @EpisodeID) IF @ID = 0  SET @IsNew = 1 ELSE SET @IsNew = 2", caseIRPs.PATSEpisodeID);
        //    foreach (var item in caseIRPs.IRPSetList)
        //    {
        //        var NeedStatus = (int?)null;
        //        if (item.NeedStatus1.HasValue && item.NeedStatus1.Value == true)
        //            NeedStatus = 1;
        //        else if (item.NeedStatus2.HasValue && item.NeedStatus2.Value == true)
        //            NeedStatus = 2;
        //        else if (item.NeedStatus3.HasValue && item.NeedStatus3.Value == true)
        //            NeedStatus = 3;
        //        else if (item.NeedStatus4.HasValue && item.NeedStatus4.Value == true)
        //            NeedStatus = 4;

        //        var LongTermStatus = (int?)null;
        //        if (item.LongTermStatusMet.HasValue && item.LongTermStatusMet.Value == true)
        //            LongTermStatus = 1;
        //        else if (item.LongTermStatusNoMet.HasValue && item.LongTermStatusNoMet.Value == true)
        //            LongTermStatus = 0;
        //        //1379 pats user id
        //        var queryIRP = string.Format(@" INSERT INTO [dbo].[CaseIRP]([EpisodeID],[NeedId],[NeedStatus],[DescriptionCurrentNeed],
        //            [Note],[ShortTermGoal],[LongTermGoal],[LongTermStatus],[LongTermStatusDate],[PlanedIntervention],
        //            [ActionStatus],[ActionBy],[DateAction],[BassUserID]) VALUES (@EpisodeID,{0},(CASE WHEN {1} = 0 
        //             THEN null ELSE {1} END),{2},{3},{4},{5},(CASE WHEN {6} = -1 THEN null ELSE {6} END),{7},{8},@IsNew,1379,@IRpDate, {9}) ", 
        //             item.NeedID, (NeedStatus == (int?)null ? 0 : NeedStatus),
        //          (string.IsNullOrEmpty(item.DescriptionCurrentNeed) ? "null" : "'" + RemoveUnprintableChars(item.DescriptionCurrentNeed) + "'"),
        //          (string.IsNullOrEmpty(item.Note) ? "null" : "'" + RemoveUnprintableChars(item.Note) + "'"),
        //          (string.IsNullOrEmpty(item.ShortTermGoal) ? "null" : "'" + RemoveUnprintableChars(item.ShortTermGoal) + "'"),
        //          (string.IsNullOrEmpty(item.LongTermGoal) ? "null" : "'" + RemoveUnprintableChars(item.LongTermGoal) + "'"), (LongTermStatus == (int?)null ? -1 : LongTermStatus),
        //          (item.LongTermStatusDate != (DateTime?)null ? "'" + item.LongTermStatusDate + "'" : "null"), 
        //          (string.IsNullOrEmpty(item.PlanedIntervention) ? "null" : "'" + RemoveUnprintableChars(item.PlanedIntervention) + "'"), CurrentUser.UserID);
        //        if (item.NeedID == 1)
        //        {
        //            queryIRP = queryIRP + " SET @ID=@@IDENTITY ";
        //        }
        //        query = query + queryIRP;

        //    }
        //    query = query + " UPDATE dbo.EpisodeTrace SET IRPID=@ID WHERE EpisodeID=@EpisodeID SELECT @ID ";
        //    var results = SqlHelper.ExecutePATSCommand(query);
        //    return null;
        //    //return PartialView("_IRP", new IRP
        //    //{
        //    //    PATSEpisodeID = (int)(results[1]),
        //    //    IRPSetList = (List<IRPSet>)results[0],
        //    //    ActionUserName = CurrentUser.UserLFI(),
        //    //    CanEdit = true
        //    //});
        //}    
        public PartialViewResult SaveApplication(ApplicationEditor AppData)
        {
            if (ModelState.IsValid)
            {
                var query = string.Format(@"DECLARE @ApplicationID int = {13}
               IF @ApplicationID > 0
                BEGIN
            INSERT INTO [dbo].[ApplicationTrace]([ApplicationID],[ApplicationTypeID],[EpisodeID]
                                ,[ApplicationOutcomeID],[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate]
                                ,[OutcomeDate],[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID],[CustodyFacilityId]
                                ,[DateAction]) 
            SELECT [ApplicationID],[ApplicationTypeID],[EpisodeID],[ApplicationOutcomeID],[AgreesToApply]
                  ,[AppliedOrRefusedOnDate],[PhoneInterviewDate],[OutcomeDate],[BICNum],[IssuedOnDate],[ArchivedOnDate]
                  ,[CreatedByUserID],[CustodyFacilityId],[DateAction]
             FROM [dbo].[Application] WHERE ApplicationID  = @ApplicationID
                  UPDATE [dbo].[Application] SET [ApplicationTypeID] ={0} ,[EpisodeID] ={1}
                    ,[ApplicationOutcomeID] = {2},[AgreesToApply] = {3},[AppliedOrRefusedOnDate] = {4}
                    ,[PhoneInterviewDate] = {5}, [OutcomeDate]= {6},[BICNum] = {7},[IssuedOnDate] = {8}
                    ,[ArchivedOnDate] = {9},[CreatedByUserID] = {10},[CustodyFacilityId] = {11}
                    ,[DateAction] = GetDate(),[DHCSDate] = {12} WHERE ApplicationID = {13} 
                END
               ELSE
               BEGIN
                 IF NOT EXISTS(SELECT 1 FROM [dbo].[Application] WHERE EpisodeID  = {1} AND [ApplicationTypeID] = {0} AND [ArchivedOnDate] IS NULL )
                   BEGIN
              INSERT INTO [dbo].[Application]([ApplicationTypeID],[EpisodeID]
                    ,[ApplicationOutcomeID],[AgreesToApply],[AppliedOrRefusedOnDate],[PhoneInterviewDate]
                    ,[OutcomeDate],[BICNum],[IssuedOnDate],[ArchivedOnDate],[CreatedByUserID],[CustodyFacilityId]
                    ,[DateAction]) VALUES({0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11}, GetDate())
                 END
                 ELSE
                 BEGIN
                     UPDATE [dbo].[Application] SET [ApplicationTypeID] ={0} ,[EpisodeID] ={1}
                    ,[ApplicationOutcomeID] = {2},[AgreesToApply] = {3},[AppliedOrRefusedOnDate] = {4}
                    ,[PhoneInterviewDate] = {5}, [OutcomeDate]= {6},[BICNum] = {7},[IssuedOnDate] = {8}
                    ,[ArchivedOnDate] = {9},[CreatedByUserID] = {10},[CustodyFacilityId] = {11}
                    ,[DateAction] = GetDate(),[DHCSDate] = {12} WHERE ApplicationID = {13} 
                 END
              END
              EXEC dbo.[spGetApplicationByType] {1},{10},{0}",
           AppData.App.ApplicationTypeID, AppData.App.EpisodeID,
           AppData.App.ApplicationOutcomeID.HasValue ? AppData.App.ApplicationOutcomeID.ToString() : "null",
           AppData.App.AgreesToApply.HasValue ? (AppData.App.AgreesToApply.Value == true ? "1" : "0") : "null",
           AppData.App.AppliedOrRefusedOnDate.HasValue ? "'" + AppData.App.AppliedOrRefusedOnDate.Value.ToShortDateString() + "'" : "null",
           AppData.App.PhoneInterviewDate.HasValue ? "'" + AppData.App.PhoneInterviewDate.Value.ToShortDateString() + "'" : "null",
           AppData.App.OutcomeDate.HasValue ? "'" + AppData.App.OutcomeDate.Value.ToShortDateString() + "'" : "null",
           string.IsNullOrEmpty(AppData.App.BICNum) ? "null" : "'" + AppData.App.BICNum + "'",
           AppData.App.IssuedOnDate.HasValue ? "'" + AppData.App.IssuedOnDate.Value.ToShortDateString() + "'" : "null",
           AppData.App.ArchivedOnDate.HasValue ? "'" + AppData.App.ArchivedOnDate.Value.ToShortDateString() + "'" : "null",
           CurrentUser.UserID, AppData.App.CustodyFacilityId.HasValue ? AppData.App.CustodyFacilityId.ToString() : "null",
           AppData.App.DHCSDate.HasValue ? "'" + AppData.App.DHCSDate.Value.ToShortDateString() + "'" : "null", AppData.App.ApplicationID);

                var results = SqlHelper.ExecuteMultipleAppCommands(query).ToList();

                bool needbic = false;
                bool needPI = false;
                string appName = string.Empty;
                if (AppData.App.ApplicationTypeID == 2)
                {
                    appName = "MediCal";
                    needbic = true;
                }
                else if (AppData.App.ApplicationTypeID == 1)
                    appName = "VA";
                else if (AppData.App.ApplicationTypeID == 0)
                {
                    appName = "SSI";
                    needPI = true;
                }
                return PartialView("_ApplicationEditor", new ApplicationEditor
                {
                    App = (ApplicationData)results[2],
                    ApplicationTypeName = appName,
                    ErrorMessage = "",
                    Facilities = ((List<Facility>)results[0]),
                    Outcomes = (List<OutcomeType>)results[1],
                    Needbic = needbic,
                    NeedPI = needPI
                });
            }
            return null;
        }
        [HttpPost]
        public PartialViewResult ArchiveApplication(int ApplicationID, int ApplicationTypeID, int EpisodeID )
        {
            List<ParameterInfo> parms = new List<ParameterInfo>
            {
                new ParameterInfo {  ParameterName= "ApplicationID", ParameterValue = ApplicationID },
                new ParameterInfo {  ParameterName= "EpisodeID", ParameterValue = EpisodeID },
                new ParameterInfo {  ParameterName= "CurrentUserID", ParameterValue = CurrentUser.UserID }
            };
            SqlHelper.ExecuteQuery("spSaveArchivedApp", parms);
            //var query = string.Format(@"UPDATE [dbo].[Application] SET [ArchivedOnDate] =GetDate() WHERE ApplicationID ={0}", ApplicationID);
            //var result = SqlHelper.ExecuteCommand(query);
            var needbic = false;
            var needPI = false;
            string appName = string.Empty;
            if (ApplicationTypeID == 2)
            {
                appName = "MediCal";
                needbic = true;
            }
            else if (ApplicationTypeID == 1)
                appName = "VA";
            else if (ApplicationTypeID == 0)
            {
                appName = "SSI";
                needPI = true;
            }
            var model = new ApplicationData();
            model.ApplicationID = 0;
            model.AgreesToApply = null;
            model.ApplicationOutcomeID = null;
            model.AppliedOrRefusedOnDate = null;
            model.CustodyFacilityId = null;
            model.OutcomeDate = null;
            model.PhoneInterviewDate = null;
            model.CreatedByUserID = CurrentUser.UserID;
            model.EpisodeID = EpisodeID;
            model.IsEditable = true;
            model.ApplicationTypeID = ApplicationTypeID;
            return PartialView("_ApplicationEditor", new ApplicationEditor
            {
                App = model,
                ApplicationTypeName = appName,
                ErrorMessage = "",
                Facilities = null,
                Outcomes = null,
                Needbic = needbic,
                NeedPI = needPI
            });
        }
        public ActionResult MyAssignmentRead([DataSourceRequest] DataSourceRequest request, int BenefitWorkerId)
        {
            if (BenefitWorkerId == 0)
            {
                if (CurrentUser.IsBenefitWorker)
                    BenefitWorkerId = CurrentUser.UserID;
                else
                    return Json(null, JsonRequestBehavior.AllowGet);
            }
            List<ParameterInfo> parameters = new List<ParameterInfo>()
            {
                new ParameterInfo { ParameterName = "BenefitWorkerId", ParameterValue = BenefitWorkerId } };
            var query = SqlHelper.GetRecords<BenefitWorkerAssignedCase>("spGetBenefitWorkerAssignedCaseV3", parameters).ToList();
            
            return Json(query.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        
        public JsonResult GetAllSearchResults(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return Json(null, JsonRequestBehavior.AllowGet);
            }

            var result = GetSearchResults(text);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public JsonResult GetIRPDateList(int EpisodeID)
        {
            var query = string.Format("DECLARE @EpisodeID int = {0} " +
               "DECLARE @ID int = ISNULl((SELECT IRPID FROM EPisodeTrace WHERE EpisodeID = @EpisodeID), 0) " +
               "IF @ID = 0" +
               " SELECT 0 AS IRPID, (CONVERT(NVARCHAR(15), GetDate(), 110) + '*') AS IRPDate " +
               "ELSE " +
                 " SELECT id as IRPID, (CONVERT(NVARCHAR(15), DateAction, 110) + " +
                 " (CASE WHEN id = @ID THEN '*' ELSE '' END)) as IRPDate " +
                 " From dbo.CaseIRP Where EpisodeID = @EpisodeID AND NeedId = 1 AND ActionStatus <> 10 ORDER BY DateAction DESC", EpisodeID);
            var dates = SqlHelper.ExecutePATSCommands<IRPDates>(query);
            return Json(dates, JsonRequestBehavior.AllowGet);
        }
        private List<IRPSet> GetIRPListData(string CDCR, int IRPID)
        {
            List<ParameterInfo> parms = new List<ParameterInfo> {
                { new ParameterInfo {  ParameterName= "CDCRNum", ParameterValue = CDCR } },
                { new ParameterInfo {  ParameterName= "IRPID", ParameterValue = IRPID }} };
            var results = SqlHelper.GetMultiPATSSets<dynamic>("spGetPATSEpisodeIRPToBASS", parms, 2);
            return null;
        }
        //<LastOrCDCR>|<Facility>|<BenefitWorkerId>|<ProgramStatus>
        private List<EpisodeAssignedList> GetSearchResults(string SearchString)
        {
            List<EpisodeAssignedList> list = new List<EpisodeAssignedList>();
            List<ParameterInfo> parameters = new List<ParameterInfo>()
            {
                new ParameterInfo { ParameterName = "SearchString", ParameterValue = SearchString } };
            return SqlHelper.GetRecords<EpisodeAssignedList>("spGetEpisodeDropDownListV3", parameters).ToList();
        }
        public ActionResult GetInmateData(int EpisodeID)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            parameters.Add(new ParameterInfo() { ParameterName = "All", ParameterValue = 1 });
            //get object list
            List<string> objlist = new List<string>();
            objlist.Add("DerivedSomsData");
            objlist.Add("InmateProfileData");
            objlist.Add("Episodes");
            objlist.Add("Counties");
            objlist.Add("Facilities");
            objlist.Add("Genders");
            objlist.Add("EpisodeAcpDshTypes");
            objlist.Add("EpisodeMdoSvpTypes");
            objlist.Add("EpisodeMedReleaseTypes");
            objlist.Add("Destinations");
            //objlist.Add("SomsReleaseDates");
            objlist.Add("ApplicationFlags");           
            var results = SqlHelper.GetInmateDetails<object>("spGetInmateProfile", parameters, objlist);
            var episodes = ((List<Episodes>)results[2]).ToList();
            var allf = ((List<Facility>)results[4]).ToList();
            InmateProfileData profile = (InmateProfileData)results[1];
            var isLatest = (episodes.Where(w => w.EpisodeID == EpisodeID).FirstOrDefault().ReferralDate).IndexOf('*') > 0 ? true : false;
            var Editingable = isLatest && HasEditPermission(CurrentUser, profile.BenefitWorkerID);
            OffenderData offender = new OffenderData {
                EditingEnabled = Editingable,  
                IsUnassignedCase = string.IsNullOrEmpty(profile.BenefitWorkerName) && isLatest && CurrentUser.IsBenefitWorker,
                DerivedSomsData = (DerivedSomsData)results[0],
                Inmate = profile,
                AllEpisodes = episodes,
                AllCounties = ((List<County>)results[3]).ToList(),
                AllFacilities = allf,
                AllGenders = ((List<Gender>)results[5]).ToList(),
                AllAcpDshTypes = ((List<EpisodeAcpDshType>)results[6]).ToList(),
                AllMdoSvpTypes = ((List<EpisodeMdoSvpType>)results[7]).ToList(),
                AllMedReleaseTypes = ((List<EpisodeMedReleaseType>)results[8]).ToList(),
                AllDestinationIDs = ((List<LookUpTable>)results[9]).ToList()                  
                //SomsReleaseDates = ((List<ReleaseDateChanged>)results[10]).ToList()
            };

            Applications apps = new Applications
            {
                 //AllOutcomes = ((List<OutcomeType>)results[10]).ToList(),
                 //AppData = ((List<ApplicationData>)results[12]).ToList(),
                 AppFlags = (ApplicationFlags)results[10],
                 CanEditApplication = Editingable,
                 //AllFacilities = allf,
                 User = CurrentUser
            };

            CaseNoteFiles casenf = new CaseNoteFiles
            {
                CanEditNote = Editingable || CurrentUser.CanEditAllNotes,
                EpisodeID = EpisodeID,
                HideCaseNote = CurrentUser.CaseNoteHidden,
                HideDocument = CurrentUser.DocumentHidden,
                CanUploadFile = Editingable || CurrentUser.CanEditAllCases
            };
            
            return PartialView("_InmatePanel", new InmateData
            {
                ShowCaseNoteList = CurrentUser.CanAccessReports,
                Offender = offender,
                Appliations = apps,
                CaseNF = casenf,
                EpisodeID = EpisodeID
            });
        }
        public ActionResult GetReleaseDateChangs([DataSourceRequest] DataSourceRequest request, int EpisodeID)
        {
            var query = string.Format(@"SELECT FileDate, ScheduledReleaseDate FROM  [dbo].[fnGetReleaseHistory]({0})", EpisodeID);
            //'BE3758'
            //List<ReleaseDateChanges> rdChanges = new List<ReleaseDateChanges>();
            var rdChanges = SqlHelper.ExecuteCommands<ReleaseDateChanged>(query, 1).ToList();
            //rdChanges = db.SomsRecords.Where(x => x.CDCNumber == CDCNo).GroupBy(g => g.ScheduledReleaseDate)
            //                  .Select(g => g.OrderBy(x => x.FileDate).FirstOrDefault())
            //                  .Select(s => new ReleaseDateChanges { FileDate = s.FileDate, ScheduledReleaseDate = s.ScheduledReleaseDate.HasValue ? s.ScheduledReleaseDate.Value : (DateTime?)null })
            //                  .OrderBy(o => o.FileDate).ToList();

            return Json(rdChanges.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public ActionResult SaveOffenderData(OffenderData submitModel)
        {
            if (ModelState.IsValid)
            {
                if (submitModel.Inmate.ScreeningDate.HasValue)
                    submitModel.Inmate.ScreeningDateSetByUserID = CurrentUser.UserID;
                var query = string.Format(@"DECLARE @ScreeningDate DateTime ={4} DECLARE @AuthToRepresent bit = {5} DECLARE @ReleaseOfInfoSigned bit = {6}
              Update dbo.Episode SET ReleaseDate ={1}, CustodyFacilityID={2}, Housing={3}, ScreeningDate={4}, AuthToRepresent ={5}, ReleaseOfInfoSigned={6}, CalFreshRef ={7}, CalWorksRef = {8}, CIDServiceRefusalDate = {9}, ReleasedToPRCS ={10}, Lifer = {11},ReleaseCountyID ={12}, DestinationID ={13}, ScreeningDateSetByUserID ={34} WHERE EpisodeID = {0}
                  IF @ScreeningDate IS NULL AND @AuthToRepresent= 0 AND @ReleaseOfInfoSigned = 0 BEGIN 
                        Update dbo.Episode SET ApplyForMediCal = 0, ApplyForSSI = 0, ApplyForVA = 0 WHERE EpisodeID = {0}
                     END
               UPDATE dbo.Offender SET DOB ={15}, GenderID ={16}, MiddleName ={17}, LongTermMedCare ={18}, PC290 ={19}, PC457 ={20}, Hospice ={21}, AssistedLiving ={22}, ChronicIllness ={23}, EOP ={24}, CCCMS ={25}, DSH ={26}, PhysDisabled ={27}, DevDisabled = {28},HIVPos ={29}, USVet ={30}, ReviewStatus={31}, Elderly ={32}, SSN ={33} WHERE OffenderID = {14}
              INSERT INTO [dbo].[EpisodeOffender](EpisodeID, MiddleName, PC290, PC457,USVet, SSN,DOB, GenderID, LongTermMedCare, Hospice,AssistedLiving, HIVPos, ChronicIllness, EOP, 
               PhysDisabled, DevDisabled, CCCMS, Elderly,DSH,ReleaseCountyID,ScreeningDate,AuthToRepresent, ReleaseOfInfoSigned,ReleasedToPRCS,        
               CIDServiceRefusalDate,ReleaseDate,Housing,CustodyFacilityID, Lifer, ScreeningDateSetByUserID, DestinationID, CalFreshRef, CalWorksRef,   
			   ActionBy, DateAction)
             VALUES ({0},{17},{19},{20},{30},{33},{15},{16},{18},{21},{22},{29},{23},{24},
	           {27},{28},{25},{32},{26},{12},{4},{5},{6},{10},{9},{1},{3},{2},{11},{34},{13},{7},{8},			   
			   {35}, GetDate())
              EXEC [dbo].[spGetInmateProfile] {0}, {35}, 0",
                  submitModel.Inmate.EpisodeID,
                  submitModel.Inmate.ReleaseDate.HasValue ? "'" + submitModel.Inmate.ReleaseDate + "'" : "null",
                  submitModel.Inmate.CustodyFacilityID.HasValue ? submitModel.Inmate.CustodyFacilityID.Value.ToString() : "null",
                  string.IsNullOrEmpty(submitModel.Inmate.Housing) ? "null" : "'" + submitModel.Inmate.Housing + "'",
                  submitModel.Inmate.ScreeningDate.HasValue ? "'" + submitModel.Inmate.ScreeningDate.Value + "'" : "null",
                  submitModel.Inmate.AuthToRepresent ? "1" : "0", 
                  submitModel.Inmate.ReleaseOfInfoSigned ? "1" : "0",
                  ((!submitModel.Inmate.CalFreshRef.HasValue) ? "null" : (submitModel.Inmate.CalFreshRef.Value == true ? "1" : "0")),
                  ((!submitModel.Inmate.CalWorksRef.HasValue) ? "null" : (submitModel.Inmate.CalWorksRef.Value == true ? "1" : "0")), 
                  submitModel.Inmate.CIDServiceRefusalDate.HasValue ? "'" + submitModel.Inmate.CIDServiceRefusalDate.Value + "'" : "null",
                  ((!submitModel.Inmate.ReleasedToPRCS.HasValue) ? "null" : (submitModel.Inmate.ReleasedToPRCS.Value == true ? "1" : "0")),
                  submitModel.Inmate.Lifer ? "1" : "0",
                  submitModel.Inmate.ReleaseCountyID.HasValue ? submitModel.Inmate.ReleaseCountyID.Value.ToString() : "null",
                  submitModel.Inmate.DestinationID.HasValue ? submitModel.Inmate.DestinationID.Value.ToString() : "null",
                  submitModel.Inmate.OffenderID,
                  submitModel.Inmate.DOB.HasValue ? "'" + submitModel.Inmate.DOB.Value + "'" : "null", submitModel.Inmate.GenderID,
                  string.IsNullOrEmpty(submitModel.Inmate.MiddleName) ? "null" : "'" + submitModel.Inmate.MiddleName + "'",
                  submitModel.Inmate.LongTermMedCare ? "1" : "0", submitModel.Inmate.PC290 ? "1" : "0", submitModel.Inmate.PC457 ? "1" : "0", 
                  submitModel.Inmate.Hospice ? "1" : "0", submitModel.Inmate.AssistedLiving ? "1" : "0", 
                  submitModel.Inmate.ChronicIllness ? "1" : "0", submitModel.Inmate.EOP ? "1" : "0", submitModel.Inmate.CCCMS ? "1" : "0",
                  submitModel.Inmate.DSH ? "1" : "0", submitModel.Inmate.PhysDisabled ? "1" : "0", 
                  submitModel.Inmate.DevDisabled ? "1" : "0", submitModel.Inmate.HIVPos ? "1" : "0",
                  submitModel.Inmate.USVet ? "1" : "0", submitModel.Inmate.ReviewStatus, submitModel.Inmate.Elderly ? "1" : "0",
                  string.IsNullOrEmpty(submitModel.Inmate.SSN) ? "999-99-9999" : "'" + submitModel.Inmate.SSN + "'",
                  submitModel.Inmate.ScreeningDateSetByUserID.HasValue ? submitModel.Inmate.ScreeningDateSetByUserID.Value.ToString() : "null", CurrentUser.UserID
                  );

                var results = SqlHelper.ExecuteCommandsWithReturnList<object>(query).ToList();
                DerivedSomsData SomsData = (DerivedSomsData)results[0];
                InmateProfileData profile = (InmateProfileData)results[1];
                var episodes = ((List<Episodes>)results[2]).ToList();
                var isLatest = (episodes.Where(w => w.EpisodeID == submitModel.Inmate.EpisodeID).FirstOrDefault().ReferralDate).IndexOf('*') > 0 ? true : false;

                return PartialView("_OffenderData", new OffenderData
                {
                    EditingEnabled = isLatest && HasEditPermission(CurrentUser, profile.BenefitWorkerID),
                    DerivedSomsData = SomsData,
                    Inmate = profile,
                    AllEpisodes = episodes,
                    AllCounties = ((List<County>)results[3]).ToList(),
                    AllFacilities = ((List<Facility>)results[4]).ToList(),
                    AllGenders = ((List<Gender>)results[5]).ToList(),
                    AllAcpDshTypes = ((List<EpisodeAcpDshType>)results[6]).ToList(),
                    AllMdoSvpTypes = ((List<EpisodeMdoSvpType>)results[7]).ToList(),
                    AllMedReleaseTypes = ((List<EpisodeMedReleaseType>)results[8]).ToList(),
                    AllDestinationIDs = ((List<LookUpTable>)results[9]).ToList()
                });
            }
              return ErrorsJson(ModelStateErrors());
        }
        [HttpPost]
        public ActionResult OpenApplication(int EpisodeID, List<Facility> Facilities)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            
            var result = SqlHelper.GetRecords<ApplicationFlags>("spGetApplications", parameters);
            return PartialView("_Applications", new Applications
            {
                CanEditApplication = HasEditPermission(CurrentUser,0),
                User =  CurrentUser,
                AppFlags = result.FirstOrDefault()
            });
        }
        [HttpPost]
        public ActionResult LoadCaseNoteFile(int EpisodeID)
        {
            return PartialView("_CaseNoteFile", new CaseNotes {
                EpisodeID = EpisodeID, CanEdit = (CurrentUser.IsBenefitWorker || CurrentUser.CanAccessReports)
            });
        }
        public PartialViewResult GetApplicationBox(int EpisodeID, int AppTypeID)
        {
            bool needbic = false;
            bool needPI = false;
            string appName = string.Empty;
            if (AppTypeID == 2)
            {
                appName = "MediCal";
                needbic = true;
            }
            else if (AppTypeID == 1)
                appName = "VA";
            else if (AppTypeID == 0)
            {
                appName = "SSI";
                needPI = true;
            }

            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            parameters.Add(new ParameterInfo() { ParameterName = "ApplicationTypeID", ParameterValue = AppTypeID });
            List<string> Objects = new List<string>{ "Facilities", "Outcomes", "ApplicationData" };
            var result = SqlHelper.GetInmateDetails<object>("spGetApplicationByType", parameters, Objects);
               
            return PartialView("_ApplicationEditor", new ApplicationEditor
            {
                App = (ApplicationData)result[2],
                ApplicationTypeName = appName,
                ErrorMessage = "",
                Facilities= (List<Facility>)result[0],
                Outcomes = (List<OutcomeType>)result[1],
                Needbic = needbic,
                NeedPI = needPI
            });
        }
        public ActionResult GetArchivedApplications([DataSourceRequest]DataSourceRequest request, int EpisodeID)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            var result = SqlHelper.GetRecords<ArchiveApplicationData>("spGetArchivedApps", parameters);
           
            return Json((result).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public bool RestoreApplication(int ApplicationId, int ApplicationTypeID, int EpisodeID)
        {
            var colName = "";
            if (ApplicationTypeID == 0)
            {
                colName = "ApplyForSSI";
            }
            else if (ApplicationTypeID == 1)
            {
                colName = "ApplyForVA";
            }
            else
            {
                colName = "ApplyForMediCal";
            }
            var query = string.Format(@"UPDATE dbo.[Application] SET  ArchivedOnDate = null WHERE ApplicationID = {0}
           UPDATE dbo.[Episode] SET {1} = 1 WHERE EpisodeID = {2}", ApplicationId, colName, EpisodeID);

            var result = SqlHelper.ExecuteCommand(query, 1);
            return true;
        }
        public ActionResult GetApplicationReadonly(int ApplicationID)
        {
            var query = string.Format(@"SELECT t1.ApplicationID, t1.ApplicationTypeID, t1.AgreesToApply, t2.Name AS ApplicationTypeName, 
                t1.AppliedOrRefusedOnDate, t1.ArchivedOnDate, t1.PhoneInterviewDate, t1.IssuedOnDate, t1.OutcomeDate, 
                t3.Abbr AS CustodyFacility, t4.Name AS Outcome, t1.BICNum
                From dbo.[Application] t1 INNER JOIN dbo.[ApplicationType] t2 ON t1.ApplicationTypeID = t2.ApplicationTypeID 
                 LEFT OUTER JOIN dbo.[Facility] t3 ON t1.CustodyFacilityID = t3.FacilityID
                 LEFT OUTER JOIN dbo.[ApplicationOutcome] t4 ON t1.ApplicationOutcomeID = t4.ApplicationOutcomeID
               WHERE ApplicationID  = {0}", ApplicationID);
            var result = SqlHelper.ExecuteCommands<ArchiveApplicationReadData>(query, 1).FirstOrDefault();
            
            return PartialView("_ApplicationReadonly", result);
        }
        public ActionResult CaseNoteRead([DataSourceRequest]DataSourceRequest request, int EpisodeID)
        {
            var results = GetCaseNotes(EpisodeID, "", 0);
            return Json(results.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        public ActionResult CaseNoteHisRead([DataSourceRequest]DataSourceRequest request, int EpisodeId)
        {
            var notes = GetCaseNotes(EpisodeId, "ALL", 0);
            return Json(notes.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        public ActionResult HierarchyBinding_Note([DataSourceRequest] DataSourceRequest request, int EpisodeID, int CaseNoteTraceId)
        {
            List<CaseNoteData> casenotes = GetCaseNotes(EpisodeID, "", CaseNoteTraceId);

            return Json(casenotes.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public JsonResult CaseNoteCreate([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<CaseNoteData> casenotes, int EpisodeId)
        {
            if (casenotes != null && ModelState.IsValid)
            {
                var noteTemp = casenotes.FirstOrDefault();
                casenotes = SaveCaseNote(noteTemp, EpisodeId);
            }
            return Json(casenotes.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult CaseNoteUpdate([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<CaseNoteData> casenotes, int EpisodeId)
        {
            if (casenotes != null && ModelState.IsValid)
            {
                var noteTemp = casenotes.FirstOrDefault();
                casenotes = SaveCaseNote(noteTemp, EpisodeId); // as IEnumerable<CaseNoteData>;
            }
            return Json(casenotes.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }
        public ActionResult CaseNoteDelete([DataSourceRequest] DataSourceRequest request, [Bind(Prefix = "models")]IEnumerable<CaseNoteData> casenotes)
        {
            if (ModelState.IsValid && casenotes != null)
            {
                int Id = casenotes.ToList().FirstOrDefault().CaseNoteTraceID;
                DeleteCaseNote(Id);
            }

            return Json(new[] { casenotes }.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }
        private int DeleteCaseNote(int CasenoteTraceID)
        {
            var query = string.Format(@"UPDATE dbo.[CaseNote] SET ActionStatus = 10 Where CaseNoteTraceID = {0}", CasenoteTraceID);
            return SqlHelper.ExecuteCommand(query, 1);
        }
        private List<CaseNoteData> SaveCaseNote(CaseNoteData CaseNote, int EpisodeID)
        {
            if (CaseNote != null)
            {
                var actionStatus = CaseNote.CaseNoteID == 0 ? (int)ACTION_STATUS.New : (int)ACTION_STATUS.Update;
                var query = string.Format(@"INSERT INTO dbo.[CASENOTE] (EpisodeID, USERID, ActionStatus,CaseNoteTraceID, 
                     EventDate,CaseNoteTypeID, CaseNoteTypeReasonID, Text, ActionBy, CreatedDateTime)
                      VALUES ({0},{1},{2}, {3},{4}, {5}, {6}, {7}, {8}, GetDate())
                      IF {2} = 1 UPDATE dbo.[CASENOTE] SET CaseNoteTraceID = @@IDENTITY WHERE CaseNoteTraceID = 0 AND EpisodeID = {0}",
                      EpisodeID, CaseNote.UserID > 0 ? CaseNote.UserID : CurrentUser.UserID, actionStatus, CaseNote.CaseNoteTraceID, 
                      CaseNote.EventDate.HasValue ? "'" + CaseNote.EventDate + "'" : "null", CaseNote.CaseNoteTypeID,
                      CaseNote.CaseNoteTypeReasonID.HasValue ? "'" + CaseNote.CaseNoteTypeReasonID.ToString() + "'" : "null", 
                      "'" + RemoveUnprintableChars(CaseNote.Text) + "'", CurrentUser.UserID);
                return SqlHelper.ExecuteCommands<CaseNoteData>(query, 1);
            }
            return null;
        }
        public ActionResult FilesRead([DataSourceRequest] DataSourceRequest request, int EpisodeId)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeId });
            var result = SqlHelper.GetRecords<UploadedFiles>("spGetUploadedFiles", parameters);
            return Json(result.ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        public ActionResult FilesDestroy([DataSourceRequest] DataSourceRequest request, UploadedFiles file)
        {
            if (file != null)
            {
                var query = string.Format(@"UPDATE [dbo].[DocUpload] SET ActionStatus = 10 WHERE ID = {0}", file.ID);
                var result = SqlHelper.ExecuteCommand(query, 1);
            }

            return Json(new[] { file }.ToDataSourceResult(request, ModelState));
        }
        public ActionResult SaveUploadFile(IEnumerable<HttpPostedFileBase> files, int EpisodeId)
        {
            if (files != null)
            {
                foreach (var file in files)
                {
                    //copy file to server
                    if (files != null)
                    {
                        var fileName = Path.GetFileNameWithoutExtension(file.FileName)  + ".pdf";   //+ DateTime.Now.ToString("MMddyyyyhhmm")
                        var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), fileName);
                        // The files are not actually saved in disk
                        file.SaveAs(physicalPath);

                        var query = string.Format(@"INSERT INTO [dbo].[DocUpload]([EpisodeId],[FileTypeId],[FileName]
           ,[FileSize],[ActionStatus],[ActionBy],[DateAction]) VALUES ({0},1,{1},{2}, 1, {3}, GetDate())",
           EpisodeId, "'" + fileName + "'", System.IO.File.ReadAllBytes(physicalPath).Length, CurrentUser.UserID );
                        var result = SqlHelper.ExecuteCommand(query, 1); 
                    }
                }
            }
            // Return an empty string to signify success
            return Content("");
        }

        public ActionResult FilterCaseNoteType_read([DataSourceRequest] DataSourceRequest request, int? EpisodeID)
        {
            return Json(GetCaseNotes(EpisodeID.Value, "", 0).Select(s => s.CaseNoteType).Distinct(), JsonRequestBehavior.AllowGet);
        }
        public ActionResult FilterCaseNoteTypeReason_read([DataSourceRequest] DataSourceRequest request, int? EpisodeID)
        {
            return Json(GetCaseNotes(EpisodeID.Value, "", 0).Where(x => x.CaseNoteTypeReasonID != null).Select(s => s.CaseNoteTypeReason).Distinct(), JsonRequestBehavior.AllowGet);
        }
        public ActionResult Download(int id)
        {
            var query = string.Format(@"SELECT ID, EpisodeId, FileName, FileData, ActionStatus FROM [dbo].[DocUpload] WHERE ID={0}", id);
            var result = SqlHelper.ExecuteCommands<UploadedFiles>(query, 1).FirstOrDefault();
            string fileName = string.Empty;
            if (result != null && !string.IsNullOrEmpty(result.FileName))
               fileName = Path.GetFileName(result.FileName);
            var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), fileName);
            byte[] data = result.FileData;

            if (System.IO.File.Exists(physicalPath))
            {
                // The files are not actually removed in this demo
                // System.IO.File.Delete(physicalPath);
                data = System.IO.File.ReadAllBytes(physicalPath);
            }
            //else
            //{
            //    if (result.FileData != null)
            //    {
            //        System.IO.File.WriteAllBytes(physicalPath, result.FileData);
            //        return File(data.ToArray(), "application/octet-stream", result.FileName);
            //    }
            //    else
            //        //throw new HttpResponseException(HttpStatusCode.InternalServerError);
            //       throw new HttpException(fileName + " File is not found.");
            //}
            return File(data.ToArray(), "application/octet-stream", result.FileName);
        }

        public static byte[] GetFilesBytes(HttpPostedFileBase file, ref int Len)
        {
            MemoryStream target = new MemoryStream();

            file.InputStream.CopyTo(target);
            var result = target.ToArray();
            Len = result.Length;
            return result;
        }
        public ActionResult Remove(string[] fileNames)
        {
            // The parameter of the Remove action must be called "fileNames"

            if (fileNames != null)
            {
                foreach (var fullName in fileNames)
                {
                    var fileName = Path.GetFileName(fullName);
                    var physicalPath = Path.Combine(Server.MapPath("~/App_Data"), fileName);

                    // TODO: Verify user permissions

                    if (System.IO.File.Exists(physicalPath))
                    {
                        // The files are not actually removed in this demo
                        // System.IO.File.Delete(physicalPath);
                    }
                }
            }
            // Return an empty string to signify success
            return Content("");
        }
        //==================================================                
        public void AppendToFile(string fullPath, Stream content)
        {
            try
            {
                using (FileStream stream = new FileStream(fullPath, FileMode.Append, FileAccess.Write, FileShare.ReadWrite))
                {
                    using (content)
                    {
                        content.CopyTo(stream);
                    }
                }
            }
            catch (IOException ex)
            {
                throw ex;
            }
        }

        public ActionResult Chunk_Upload_Save(IEnumerable<HttpPostedFileBase> files, string metaData, int EpisodeID)
        {
            if (metaData == null)
            {
                return Chunk_Upload_Async_Save(files, EpisodeID);
            }
            // var fileName = Path.GetFileNameWithoutExtension(file.FileName) + ".pdf";
            MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(metaData));
            var serializer = new DataContractJsonSerializer(typeof(ChunkMetaData));
            ChunkMetaData chunkData = serializer.ReadObject(ms) as ChunkMetaData;
            if (chunkData.ChunkIndex == 0)
            {
                ChunkFileRemove(chunkData.FileName);
            }
            string path = String.Empty;
            // The Name of the Upload component is "files"
            if (files != null)
            {
                foreach (var file in files)
                {
                    path = Path.Combine(Server.MapPath("~/BASSDoc"), chunkData.FileName);
                    AppendToFile(path, file.InputStream);
                }
            }

            FileResult fileBlob = new FileResult();
            fileBlob.uploaded = chunkData.TotalChunks - 1 <= chunkData.ChunkIndex;
            if (fileBlob.uploaded)
            {
                //var fileName = Path.GetFileNameWithoutExtension(file.FileName) + ".pdf";   //+ DateTime.Now.ToString("MMddyyyyhhmm")
                var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), chunkData.FileName);
                var query = string.Format(@"INSERT INTO [dbo].[DocUpload]([EpisodeId],[FileTypeId],[FileName]
           ,[FileSize],[ActionStatus],[ActionBy],[DateAction]) VALUES ({0},1,{1},{2}, 1, {3}, GetDate())",
                       EpisodeID, "'" + chunkData.FileName + "'", System.IO.File.ReadAllBytes(physicalPath).Length, CurrentUser.UserID);
                var result = SqlHelper.ExecuteCommand(query, 1);
            }

            fileBlob.fileUid = chunkData.UploadUid;

            return Json(fileBlob);
        }

        private void ChunkFileRemove(string file)
        {
            var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), file);
            if (System.IO.File.Exists(physicalPath))
            {
                // The files are not actually removed in this demo
                System.IO.File.Delete(physicalPath);
                var query = string.Format(@"DECLARE @ID INT =(SELECT ID FROM [dbo].[DocUpload] WHERE FileName = '{0} AND ActionStatus <> 10')
                    BEGIN
                     IF @ID > 0
                          UPDATE [dbo].[DocUpload] SET ActionStatus = 10 Where ID = @ID
                     END", file);
                var result = SqlHelper.ExecuteCommand(query, 1);
            }
        }
        public ActionResult Chunk_Upload_Remove(string[] fileNames)
        {
            // The parameter of the Remove action must be called "fileNames"

            if (fileNames != null)
            {
                foreach (var fullName in fileNames)
                {
                    var fileName = Path.GetFileName(fullName);
                    var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), fileName);

                    // TODO: Verify user permissions

                    if (System.IO.File.Exists(physicalPath))
                    {
                        // The files are not actually removed in this demo
                        System.IO.File.Delete(physicalPath);
                    }
                }
            }

            // Return an empty string to signify success
            return Content("");
        }

            public ActionResult Chunk_Upload_Async_Save(IEnumerable<HttpPostedFileBase> files, int EpisodeID)
            {
                // The Name of the Upload component is "files"
                if (files != null)
                {
                    foreach (var file in files)
                    {
                    //=============================================================
                        // Some browsers send file names with full path.
                        // We are only interested in the file name.
                        //var fileName = Path.GetFileName(file.FileName);
                        //var physicalPath = Path.Combine(Server.MapPath("~/App_Data"), fileName);

                    // The files are not actually saved in this demo
                    // file.SaveAs(physicalPath);
                    //====================================================
                    var fileName = Path.GetFileNameWithoutExtension(file.FileName) + ".pdf";   //+ DateTime.Now.ToString("MMddyyyyhhmm")
                    var physicalPath = Path.Combine(Server.MapPath("~/BASSDoc"), fileName);
                    // The files are not actually saved in disk
                    file.SaveAs(physicalPath);

                    var query = string.Format(@"INSERT INTO [dbo].[DocUpload]([EpisodeId],[FileTypeId],[FileName]
           ,[FileSize],[ActionStatus],[ActionBy],[DateAction]) VALUES ({0},1,{1},{2}, 1, {3}, GetDate())",
       EpisodeID, "'" + fileName + "'", System.IO.File.ReadAllBytes(physicalPath).Length, CurrentUser.UserID);
                    var result = SqlHelper.ExecuteCommand(query, 1);
                    
                }
                }

                // Return an empty string to signify success
                return Content("");
            }
  
        //==================================================
        private List<CaseNoteData> GetCaseNotes(int EpisodeID, string searchString, int TraceID)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "EpisodeID", ParameterValue = EpisodeID });
            parameters.Add(new ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            parameters.Add(new ParameterInfo() { ParameterName = "SearchStr", ParameterValue = searchString });
            parameters.Add(new ParameterInfo() { ParameterName = "CaseNoteTraceID", ParameterValue = TraceID });
            List<CaseNoteData> result = SqlHelper.GetRecords<CaseNoteData>("spGetCaseNotes", parameters);
            return result.OrderByDescending(o => o.EventDate).ThenByDescending(t => t.CaseNoteID).ToList();
        }
        [HttpPost]
        public ActionResult GetCaseNoteView(int EpisodeId, bool Editable)
        {
            return PartialView("_CaseNoteView", new CaseNoteFiles
            {
                EpisodeID = EpisodeId,
                CanEditNote= Editable  //(CurrentUser.IsBenefitWorker || CurrentUser.CanAccessReports)
            });
        }
        
        public ActionResult GetCaseNoteHistory(int EpisodeId)
        {
            return PartialView("_CaseNoteHistory", new CaseNoteFiles
            {
                EpisodeID = EpisodeId,
                CanEditNote = true
            });
        }
        public JsonResult GetCaseNoteTypeList(int EpisodeID)
        {
            var query = string.Format(@"DECLARE @IsHIVPos bit =
  (SELECT HIVPos FROM Episode e INNER JOIN Offender o On e.offenderID  = o.OffenderID WHERE EpisodeID = {0})
  SELECT CaseNoteTypeID, Name FROM dbo.CaseNoteType WHERE Disabled = 0 AND ((@IsHIVPos = 0 AND Name NOT like 'CID S%') OR 
  (@IsHIVPos = 1 AND 1=1 )) ORDER BY DisplayOrder", EpisodeID);
            var result = SqlHelper.ExecuteCommands<CaseNoteTypeList>(query, 1);          
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public JsonResult GetCaseNoteTypeReasonList(int? CaseNoteTypeID)
        {
            var query = string.Format(@"DECLARE @CaseNoteTypeID int = {0}
                  DECLARE @CanAccessReports bit =(SELECT ISNULl(CanAccessReports, 0) FROM [User] WHERE UserID = {1})
                  DECLARE @Report bit = (SELECT (CASE WHEN @CaseNoteTypeID = 6 AND @CanAccessReports = 1 THEN 1 ELSE 0 END))
                      SELECT CaseNoteTypeReasonID, CaseNoteTypeID, Name, Position FROM CaseNoteTypeReason
                       WHERE ISNULl(Disabled, 0)<> 1 AND 
                            ((@CaseNoteTypeID <> 6 AND CaseNoteTypeID = @CaseNoteTypeID) OR (
                            (@CaseNoteTypeID = 6 AND (@Report = 1 AND CaseNoteTypeID = @CaseNoteTypeID) OR (@Report = 0 AND CaseNoteTypeID = @CaseNoteTypeID AND CaseNoteTypeReasonID NOT IN (47, 52)))))
                      Order BY Position", CaseNoteTypeID.HasValue ? CaseNoteTypeID : 0, CurrentUser.UserID);
            var result = SqlHelper.ExecuteCommands<CaseNoteTypeReasonList>(query, 1);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        //[HttpPost]
        //public ActionResult GetEditingPane(int? selectedSearchResult)
        //{
        //    if (selectedSearchResult == null)
        //    {
        //        return DefaultOffenderData();
        //    }

        //    return PartialView("Index");
        //}
        //[ChildActionOnly]
        //public ActionResult DefaultOffenderData()
        //{
        //    return Content("");
        //}
        private bool HasEditPermission(ApplicationUser user, int? BenefitWorkerID)
        {
            var haspermission = true;
            if (!user.IsActive)
                return false;

            //check to see if the episode has been assigned to the same bf
            if (!user.CanAccessReports)
            {
                if (user.IsBenefitWorker)
                {
                    if (BenefitWorkerID != user.UserID)
                    {
                        haspermission = false;
                    }
                }
                else
                    haspermission = false;
            }

            return haspermission;
        }
        public string RemoveUnprintableChars(string value)
        {
            if (string.IsNullOrEmpty(value))
                return string.Empty;
            value = DoubleToSingleQuotes(value);
            var regex = "/[^\t\n\r\x20-\x7E]/g";

            return Regex.Replace(value, regex, "");
        }
        private string DoubleToSingleQuotes(string value)
        {
            if (string.IsNullOrEmpty(value))
                return string.Empty;
            return Regex.Replace(value, "\'", "\'\'");
        }
    }
}