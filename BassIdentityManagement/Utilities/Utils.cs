using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace BassIdentityManagement.Utilities
{
    public class Utils
    {
        public string ConnectString = string.Empty;
        public Utils(int ConnectDB){
            if(ConnectDB == 1)
                ConnectString = System.Configuration.ConfigurationManager.ConnectionStrings["BassWeb"].ConnectionString;
            else
                ConnectString = System.Configuration.ConfigurationManager.ConnectionStrings["PATSWeb"].ConnectionString;
        }
        public static String ConnectionString()
        {
            return System.Configuration.ConfigurationManager.ConnectionStrings["BassWeb"].ConnectionString;
        }
        public static String PATSConnectionString()
        {
            return System.Configuration.ConfigurationManager.ConnectionStrings["PATSWeb"].ConnectionString;
        }
        public static int ConnectTime()
        {
            return Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["DBConnectionTimeOut"]);
        }
        public static bool IfUserAuthenticated()
        {
            if (HttpContext.Current.User.Identity.IsAuthenticated)
            {
                return true;
            }
            return false;
        }

        public static bool IfUserInRole(string roleName)
        {
            if (IfUserAuthenticated())
            {
                if (HttpContext.Current.User.IsInRole(roleName))
                {
                    return true;
                }
            }
            return false;
        }

    }

}
