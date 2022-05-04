using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web;
using System.Web.Configuration;

namespace BassWebV3.DataAccess
{
    public static class BassConstants
    {
        public enum ControllerID
        {
            Unknown, CaseAssignment, EditOffender, Reports, TeamManagement
        }
        public static int MaxLoginFailures
        {
            get
            {
                return Convert.ToInt32(WebConfigurationManager.AppSettings["MaxLoginFailures"]);
            }
        }
        public static string Environment
        {
            get
            {
                return (WebConfigurationManager.AppSettings["Environment"] == "Development" ? WebConfigurationManager.AppSettings["Environment"] : "");
            }
        }

        public static string LoginTitle
        {
            get
            {
                return " - " + WebConfigurationManager.AppSettings["SiteName"] + " (" + WebConfigurationManager.AppSettings["Environment"] + ")";
            }
        }
        public static string BkgColor
        {
            get
            {
                if (WebConfigurationManager.AppSettings["Environment"] == "Development")
                    return "red";
                else
                    return "darkblue";
            }
        }
        public static bool ShowEnvironment
        {
            get
            {
                return WebConfigurationManager.AppSettings["ShowEnvironment"] == "true";
            }
        }
        public static string SiteName
        {
            get
            {
                return WebConfigurationManager.AppSettings["SiteName"];
            }
        }
        public static string ActiveDirectory
        {
            get
            {
                return WebConfigurationManager.AppSettings["ActiveDirectory"];
            }
        }
        public static string ProductionAbout
        {
            get
            {
                var appCopyRight = ((AssemblyCopyrightAttribute)Attribute.GetCustomAttribute(Assembly.GetExecutingAssembly(), typeof(AssemblyCopyrightAttribute))).Copyright.ToString();
                var appName = ((AssemblyProductAttribute)Attribute.GetCustomAttribute(Assembly.GetExecutingAssembly(), typeof(AssemblyProductAttribute))).Product.ToString();
                var appVersion = ((AssemblyFileVersionAttribute)Attribute.GetCustomAttribute(Assembly.GetExecutingAssembly(), typeof(AssemblyFileVersionAttribute))).Version.ToString();
                return appName + " (" + appVersion + ") - " + appCopyRight;
            }
        }
        public class ReleaseDateChanges
        {
            public DateTime FileDate { get; set; }
            public DateTime? ScheduledReleaseDate { get; set; }
        }
    }
}