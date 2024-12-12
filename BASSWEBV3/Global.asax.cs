using BASSWEBV3;
using BASSWEBV3.App_Start;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Helpers;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Services;

namespace BassWebV3
{
    public class MvcApplication : System.Web.HttpApplication
    {
        private string _IpAddress;
        internal string IpAddress
        {
            get { return _IpAddress= GetCustomerIP(); }
            set { this._IpAddress = value; }
        }
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            GlobalFilters.Filters.Add(new IpPropertyActionFilter(), 0);
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
            AntiForgeryConfig.SuppressIdentityHeuristicChecks = true;
        }
        protected void Application_BeginRequest(Object sender, EventArgs e)
        {
            AntiForgeryConfig.SuppressIdentityHeuristicChecks = true;
            AntiForgeryConfig.RequireSsl = HttpContext.Current.Request.IsSecureConnection;

            HttpContext.Current.Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
            HttpContext.Current.Response.Cache.SetValidUntilExpires(true);
            HttpContext.Current.Response.Cache.SetRevalidation(HttpCacheRevalidation.AllCaches);
            HttpContext.Current.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            HttpContext.Current.Response.Cache.SetNoStore();
            if (Application["IpAddress"] == null)
            {
                Application["IpAddress"] = IpAddress;
            }
        }

        [WebMethod]
        public string GetCustomerIP()
        {
            string CustomerIP = "";
            //string strHostName = System.Net.Dns.GetHostName();
            //string clientIPAddress = System.Net.Dns.GetHostAddresses(strHostName).GetValue(0).ToString();

            if (HttpContext.Current.Request.ServerVariables["HTTP_VIA"] != null)
            {
                CustomerIP = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"].ToString();
            }
            else
            {
                CustomerIP = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"].ToString();
            }
            return "'" + CustomerIP + "'";
        }
    }
}
