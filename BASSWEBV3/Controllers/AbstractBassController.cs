using BassIdentityManagement.Data;
using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Configuration;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Services;
using static BassWebV3.DataAccess.BassConstants;

namespace BassWebV3.Controllers
{
    //public enum ControllerID
    //{
    //    Unknown, CaseAssignment, EditOffender, Reports, TeamManagement
    //}
    public enum RELEASE_DESTINATION
    {
        PRCS = 1,
        Parole,
        ACP = 4,
        MDOorSVP,
        INSorICE,
        Out_of_State,
    }
    public enum ACTION_STATUS
    {
        New = 1,
        Update,
        Delete = 10
    }
    public abstract class AbstractBassController : Controller
    {
        protected ApplicationUser _currentUser;
        public enum RELEASE_DESTINATION
        {
            PRCS = 1,
            Parole,
            ACP = 4,
            MDOorSVP,
            INSorICE,
            Out_of_State,
        }

        public enum ACTION_STATUS
        {
            New = 1,
            Update,
            Delete = 10
        }
        public ApplicationUser CurrentUser
        {
            get { return _currentUser; }
            set { _currentUser = value; }
        }
        public string IpAddress
        {
            get { return HttpContext.Application["IpAddress"].ToString(); }
        }
        public string GetBassUserName(int UserID)
        {
            var parms = new List<ParameterInfo> {
                new ParameterInfo { ParameterName="UserID", ParameterValue= UserID }
            };
            return SqlHelper.GetRecord<string>("spGetBassStaffName", parms);
        }
        // GET: AbstractBass
        protected override void Initialize(RequestContext requestContext)
        {
            base.Initialize(requestContext);

            if (requestContext.HttpContext.User.Identity.IsAuthenticated)
            {
                if ((ApplicationUser)Session["Currentuser"] == null)
                {
                    try
                    {
                        List<ParameterInfo> parameters = new List<ParameterInfo>();
                        parameters.Add(new ParameterInfo() { ParameterName = "Username", ParameterValue = requestContext.HttpContext.User.Identity.Name });
                        Session["Currentuser"] = SqlHelper.GetRecord<ApplicationUser>("spGetUserByUsername", parameters);
                    }
                    catch (Exception err)
                    {
                        throw err;
                    }
                }
                _currentUser = (ApplicationUser)Session["Currentuser"];
                ViewBag.CurrentUser = _currentUser;

                if (_currentUser != null && string.IsNullOrEmpty((string)HttpContext.Application["LoginUserName"]))
                    HttpContext.Application["LoginUserName"] = _currentUser.UserName;
            }
            else
                ViewBag.ControllerID = ControllerID.Unknown;
        }
        protected override void OnException(ExceptionContext filterContext)
        {
            Exception exception = filterContext.Exception;
            filterContext.ExceptionHandled = true;

            string logDir = WebConfigurationManager.AppSettings["ErrorLogDir"].ToString();
            if (string.IsNullOrEmpty(logDir))
                logDir = "Production";
            string logSubDir = WebConfigurationManager.AppSettings["Environment"].ToString();
            string logPath = Path.Combine(logDir, logSubDir);
            string logfile = logPath + "\\BassV3Error" + DateTime.Today.ToString("MMMddyyyy") + ".txt";
            if (!System.IO.File.Exists(logfile))
            {
                System.IO.File.Create(logfile).Close();
            }
            using (StreamWriter writer = System.IO.File.AppendText(logfile))
            {
                string line = DateTime.Now.ToString("MM/dd/yyyy hh:mm ") + "        " + exception.Message;
                writer.WriteLine(line);
                writer.WriteLine("=========================================");
                writer.WriteLine();
                writer.Close();
            }
            if (exception.Message == "Object reference not set to an instance of an object." ||
                exception.Message.IndexOf("The parameters dictionary contains a null entry for") > -1 ||
                exception.Message.IndexOf("A network-related or instance-specific error occurred") > -1)
            {
                var result = this.View("Error", new HandleErrorInfo(exception, filterContext.RouteData.Values["controller"].ToString(), filterContext.RouteData.Values["action"].ToString()));
                filterContext.Result = result;
                filterContext.ExceptionHandled = true;
            }
            // Output a nice error page
            if (filterContext.HttpContext.IsCustomErrorEnabled)
            {
                var result = this.View("Error", new HandleErrorInfo(exception, filterContext.RouteData.Values["controller"].ToString(), filterContext.RouteData.Values["action"].ToString()));
                filterContext.Result = result;
            }
            filterContext.HttpContext.Response.Clear();
        }

        protected string[] ModelStateErrors()
        {
            string[] errors = null;
            var query = ModelState.Keys.SelectMany(k => ModelState[k].Errors);
            if (query != null && query.Count() > 0)
            {
                errors = query.Select(m => m.ErrorMessage).ToArray();
            }
            return errors;
        }
        protected JsonResult ErrorsJson(string[] errors)
        {
            return Json(new { success = "false", errors = errors });
        }
        public new void Dispose()
        {
            Session["Currentuser"] = null;
        }
    }
}

