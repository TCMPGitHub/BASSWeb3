using System;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Microsoft.Owin.Security;
using System.DirectoryServices.AccountManagement;
using System.Web.Configuration;
using System.IO;
using BASSWEBV3.App_Start;
using BassWebV3.DataAccess;
using BassIdentityManagement.DAL;
using BassIdentityManagement.Entities;
using System.Web.Services;

namespace BASSWEBV3.Controllers
{

    public class BASSAccountController : Controller
    {
        private ApplicationSignInManager _signInManager;
        private ApplicationUserManager _userManager;
        public ApplicationSignInManager SignInManager
        {
            get
            {
                return _signInManager ?? HttpContext.GetOwinContext().Get<ApplicationSignInManager>();
            }
            private set
            {
                _signInManager = value;
            }
        }
        public string IpAddress
        {
            get { return HttpContext.Application["IpAddress"].ToString(); }
        }
        public ApplicationUserManager UserManager
        {
            get
            {
                return _userManager ?? HttpContext.GetOwinContext().GetUserManager<ApplicationUserManager>();
            }
            private set
            {
                _userManager = value;
            }
        }
        [AllowAnonymous]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        [OutputCache(NoStore = true, Location = System.Web.UI.OutputCacheLocation.None)]
        public async Task<ActionResult> Login(LoginInfo objLogin, string returnUrl)
        {
            if (ModelState.IsValid)
            {
                var authenticated = false;
                ApplicationUser oUser = null;
                try
                {
                    oUser = await SignInManager.UserManager.FindByNameAsync(objLogin.UserName);
                }
                catch (Exception ex)
                {
                    if (ex.Message.IndexOf("error: 26") > 0)
                    {
                        ModelState.AddModelError("", "Check your computer's proxy settings");
                    }
                    else
                        ModelState.AddModelError("", ex.Message);
                    return View(objLogin);
                }
                if (oUser == null)
                {
                    ModelState.AddModelError("", "Error: User account is incorrect.");
                    return View(objLogin);
                }
                else if (!oUser.IsActive)
                {
                    ModelState.AddModelError("", "Error: User account has been disabled. Please contact your system administrator.");
                    return View(objLogin);
                }
                else if (oUser.LoginFailures > BassConstants.MaxLoginFailures)
                {
                    ModelState.AddModelError("", "Error: User account has been locked out due to multiple login tries.");
                    return View(objLogin);
                }

                //    var verified = UserManager.PasswordHasher.VerifyHashedPassword(oUser.PasswordHash, objLogin.Password);
                if (authenticated == false)
                {
                    if(oUser.IsADUser)   //(string.IsNullOrEmpty(oUser.PasswordHash))
                    {
                        try
                        {
                            PrincipalContext adContext = new PrincipalContext(ContextType.Domain, BassConstants.ActiveDirectory);
                            if (adContext.ValidateCredentials(objLogin.UserName, objLogin.Password, ContextOptions.SimpleBind | ContextOptions.SecureSocketLayer))
                            {
                                authenticated = true;
                            }
                            else
                            {
                                ModelState.AddModelError("", "Error: User account is incorrect.");
                                UserController.UpdateLoginFailure(oUser.UserID, oUser.LoginFailures++);
                                return View(objLogin);
                            }
                        }
                        catch (Exception ex)
                        {
                            ModelState.AddModelError("", "Error: User account is incorrect.");
                            UserController.UpdateLoginFailure(oUser.UserID, oUser.LoginFailures++);
                            return View(objLogin);
                        }
                    }
                    else if (UserManager.PasswordHasher.VerifyHashedPassword(oUser.PasswordHash, objLogin.Password) == PasswordVerificationResult.Success)
                    {
                        authenticated = true;
                    }
                    else
                    {
                        ModelState.AddModelError("", "Error: User account is incorrect.");
                        UserController.UpdateLoginFailure(oUser.UserID, oUser.LoginFailures++);
                        return View(objLogin);
                    }
                }
                if (authenticated == true)
                {
                    await SignInAsync(oUser, false);
                    UserController.RecordPageLoad(oUser.UserID, RouteData.Values["controller"].ToString(),
                    RouteData.Values["action"].ToString(), HttpContext.Request.HttpMethod, IpAddress);

                    UserController.UpdateLoginFailure(oUser.UserID, 0);
                    Session["CurrentUser"] = oUser;
                    return RedirectToAction("Index", "EditOffender");
                }
                else
                {
                    ModelState.AddModelError("", "Error: Invalid login details.");
                }
            }
            return View(objLogin);
        }

        // public ISecureDataFormat<AuthenticationTicket> AccessTokenFormat { get; private set; }

        [HttpPost]
        //[ValidateAntiForgeryToken]
        public ActionResult Logout()
        {
            try
            {
                var user = (ApplicationUser)Session["Currentuser"];
                if (user != null)
                {
                    UserController.RecordPageLoad(user.UserID, RouteData.Values["controller"].ToString(),
                        RouteData.Values["action"].ToString(), HttpContext.Request.HttpMethod, IpAddress);
                    AuthenticationManager.SignOut();
                }
                else
                {
                    var id = BassIdentityManagement.Data.SqlHelper.ExecuteQueryWithReturnValue(string.Format("SELECT UserID FROM dbo.[User] WHERE UserName='{0}'", HttpContext.Application["LoginUserName"]),1);
                    UserController.RecordPageLoad(id, RouteData.Values["controller"].ToString(),
                    RouteData.Values["action"].ToString(), HttpContext.Request.HttpMethod, IpAddress);
                }
            }
            catch (Exception ex)
            {
                if (!(ex.Message.IndexOf("error: 26") > 0))
                {
                    string logDir = WebConfigurationManager.AppSettings["ErrorLogDir"].ToString();
                    if (string.IsNullOrEmpty(logDir))
                        logDir = "Production";
                    string logSubDir = WebConfigurationManager.AppSettings["Environment"].ToString();
                    string logPath = Path.Combine(logDir, logSubDir);
                    string logfile = logPath + "\\BASSV3Error" + DateTime.Today.ToString("MMMddyyyy") + ".txt";
                    if (!System.IO.File.Exists(logfile))
                    {
                        System.IO.File.Create(logfile).Close();
                    }
                    using (StreamWriter writer = System.IO.File.AppendText(logfile))
                    {
                        string line = DateTime.Now.ToString("MM/dd/yyyy hh:mm ") + "        " + ex.Message;
                        writer.WriteLine(line);
                        writer.WriteLine("=========================================");
                        writer.WriteLine();
                        writer.Close();
                    }
                    //ModelState.AddModelError("", ex.Message);
                    //return RedirectToAction("Login");
                }
            }
            finally
            {
                Session.Clear();
                Session.RemoveAll();
                Session.Abandon();
                HttpContext.Application["LoginUserName"] = null;
                //ModelState.AddModelError("", "Error: Invalid login details.");        
            }
            return RedirectToAction("Login");
        }
        private async Task SignInAsync(ApplicationUser user, bool isPersistent)
        {
            AuthenticationManager.SignOut(DefaultAuthenticationTypes.ExternalCookie);
            var identity = await UserManager.CreateIdentityAsync(user, DefaultAuthenticationTypes.ApplicationCookie);
            AuthenticationManager.SignIn(new AuthenticationProperties() { IsPersistent = isPersistent }, identity);
        }
        private IAuthenticationManager AuthenticationManager
        {
            get
            {
                return HttpContext.GetOwinContext().Authentication;
            }
        }

        //[WebMethod]
        //public string GetCustomerIP()
        //{
        //    string CustomerIP = "";
        //    if (Request.ServerVariables["HTTP_VIA"] != null)
        //    {
        //        CustomerIP = Request.ServerVariables["HTTP_X_FORWARDED_FOR"].ToString();
        //    }
        //    else
        //    {
        //        CustomerIP = Request.ServerVariables["REMOTE_ADDR"].ToString();
        //    }
        //    return CustomerIP;
        //}
        protected override void Dispose(bool disposing)
        {
            if (disposing && _userManager != null)
            {
                _userManager.Dispose();
                _userManager = null;
            }

            base.Dispose(disposing);
        }
    }
}
