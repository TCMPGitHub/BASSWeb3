using System;
using Microsoft.AspNet.Identity;
using Microsoft.Owin;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.OAuth;
using Owin;
using BASSWEBV3.App_Start;
using System.Web;

[assembly: OwinStartup(typeof(BASSWEBV3.Startup), "ConfigureAuth")]
namespace BASSWEBV3
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }

        public void ConfigureAuth(IAppBuilder app)
        {
            app.CreatePerOwinContext<ApplicationUserManager>(ApplicationUserManager.Create);
            app.CreatePerOwinContext<ApplicationSignInManager>(ApplicationSignInManager.Create);
            app.UseCookieAuthentication(new CookieAuthenticationOptions
            {
                AuthenticationType = DefaultAuthenticationTypes.ApplicationCookie,
                LoginPath = new PathString(VirtualPathUtility.ToAbsolute("~/BASSAccount/Login")),
                LogoutPath = new PathString(VirtualPathUtility.ToAbsolute("~/BASSAccount/Logout")),
                //LoginPath = new PathString(VirtualPathUtility.ToAbsolute("~/")),
                //LogoutPath = new PathString(VirtualPathUtility.ToAbsolute("~/")),
                ExpireTimeSpan = System.TimeSpan.FromMinutes(90),
                SlidingExpiration = true
            });
        }
    }
}
