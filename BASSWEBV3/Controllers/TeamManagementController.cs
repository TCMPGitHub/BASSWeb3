using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using System.Data;
using System.Data.SqlClient;
using BassWebV3.Controllers;
using static BassWebV3.DataAccess.BassConstants;
using BassWebV3.ViewModels;
using BassIdentityManagement.Data;
using BassIdentityManagement.Entities;

namespace BASS.Controllers
{
    [RoutePrefix("Management")]
    public class TeamManagementController : AbstractBassController
    {
        // GET: /Reports/
        [Route]
        [HttpGet]
        public ActionResult Index()
        {
            ViewBag.ControllerID = ControllerID.TeamManagement;
            ViewBag.IsAppViewOnly = CurrentUser.ViewBenefitOnly;
            DateTime now = DateTime.Now;
            var startDate = new DateTime(now.Year, now.Month, 1);
            var endDate = (new DateTime(now.Year, now.Month, 1)).AddMonths(1).AddDays(-1);
            return View(new TeamManagement { UserID = CurrentUser.UserID, FromDate = startDate, ToDate = endDate });
        }
        public JsonResult GetSupervisorList()
        {
            var query = @"SELECT SupervisorID, (LastName + ', ' + FirstName + ' ' + ISNULl(MiddleName, ''))SupervisorName 
                            FROM dbo.[User] WHERE IsActive = 1 AND IsADUser = 1 AND UserID = SupervisorID";
            var list = SqlHelper.ExecuteCommands<SupervisorList>(query);
            return Json(list, JsonRequestBehavior.AllowGet);
        }
        public ActionResult UserList([DataSourceRequest]DataSourceRequest request, int SupervisorID)
        {
            var query = string.Format(@"SELECT UserID, FirstName, LastName, UserName, 
                          (CASE WHEN UserID = SupervisorID THEN 'Supervisor' ELSE 'Benefit Worker' END)Title
                           FROM dbo.[User] WHERE IsActive = 1 AND SupervisorID={0}", SupervisorID);
            var result = SqlHelper.ExecuteCommands<TeamManagement>(query);

            return Json(result.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }

        public ActionResult GetUsers(int SupervisorID)
        {
            if (SupervisorID > 0)
            {
                var query = string.Format(@"SELECT UserID, FirstName, LastName, UserName, 'Unknown' AS Notes, 
                          (CASE WHEN UserID = SupervisorID THEN 'Supervisor' ELSE 'Benefit Worker' END)Title
                           FROM dbo.[User] WHERE IsActive = 1 AND SupervisorID={0}", SupervisorID);
                var result = SqlHelper.ExecuteCommands<TeamManagement>(query);
                return Json(result, JsonRequestBehavior.AllowGet);
            }
            return Json(null, JsonRequestBehavior.AllowGet);
        }

        private List<CasesWorkedLocation> GetUserWorkLocationList(DateTime FromDate, DateTime ToDate, int UserID)
        {
            List<CasesWorkedLocation> list = new List<CasesWorkedLocation>();
            if (UserID > 0)
            {
                List<ParameterInfo> paramList = new List<ParameterInfo>
                {
                    new ParameterInfo { ParameterName = "StartDate", ParameterValue=FromDate },
                    new ParameterInfo { ParameterName = "EndDate", ParameterValue=ToDate },
                    new ParameterInfo { ParameterName = "UserID", ParameterValue=UserID }
                };
                list = SqlHelper.GetRecords<CasesWorkedLocation>("spTeamWorkLocationList", paramList);
            }
            return list;
        }

        public ActionResult GetLocationWorked([DataSourceRequest]DataSourceRequest request, int UserID, DateTime StartDate, DateTime EndDate)
        {
            var location = GetUserWorkLocationList(StartDate, EndDate, UserID);
            return Json(location.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }

        public ActionResult UserAndTeamCasesWorked(int UserID, DateTime StartDate, DateTime EndDate)
        {
            //get all team's user ids
            List<ParameterInfo> paramList = new List<ParameterInfo>
            {
               new ParameterInfo { ParameterName ="UserID", ParameterValue = UserID },
               new ParameterInfo { ParameterName ="StartDate", ParameterValue = StartDate },
               new ParameterInfo { ParameterName ="EndDate", ParameterValue = EndDate },
            };
            var result = SqlHelper.GetRecords<UserAndTeamCasesworked>("spGetUserAndTeamCasesWorked", paramList);           
            return Json(result, JsonRequestBehavior.AllowGet);             
        }

        public ActionResult UserAverageCasesWorked(int UserID, DateTime StartDate, DateTime EndDate)
        {
            List<ParameterInfo> paramList = new List<ParameterInfo>
            {
               new ParameterInfo { ParameterName ="UserID", ParameterValue = UserID },
               new ParameterInfo { ParameterName ="StartDate", ParameterValue = StartDate },
               new ParameterInfo { ParameterName ="EndDate", ParameterValue = EndDate },
            };
            var list = SqlHelper.GetRecords<UserAndTeamCasesworked>("spGetUserAndTeamCasesWorked", paramList).ToList();
            var CasesWordedList = new List<CasesWorded>();
            CasesWordedList = list.Where(w => w.UserTotalCasesWorked != null)
                                  .Select( s=> new CasesWorded {
                                                UserID = UserID,
                                                Date = s.Date,
                                                UserCasesWorkdTotals = s.UserTotalCasesWorked }).ToList();
            return Json(CasesWordedList, JsonRequestBehavior.AllowGet);
        }
        public ActionResult UserAppsWorked(int UserID, DateTime StartDate, DateTime EndDate)
        {
            List<ParameterInfo> paramList = new List<ParameterInfo>
            {
               new ParameterInfo { ParameterName ="UserID", ParameterValue = UserID },
               new ParameterInfo { ParameterName ="StartDate", ParameterValue = StartDate },
               new ParameterInfo { ParameterName ="EndDate", ParameterValue = EndDate },
            };
            var result = SqlHelper.GetRecords<AppModel>("spGetUserAppsWorked", paramList).ToList();

            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}