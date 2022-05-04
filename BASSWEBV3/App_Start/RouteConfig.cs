using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace BASSWEBV3
{
    public class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
            routes.MapMvcAttributeRoutes();

            routes.MapRoute(
                name: "Default",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "BASSAccount", action = "Login", id = UrlParameter.Optional }
            );

            routes.MapRoute(
                name: "Logout",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "BASSAccount", action = "Logout", id = UrlParameter.Optional }
            );

            routes.MapRoute(
                name: "EditOffender",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "EditOffender", action = "Index", id = UrlParameter.Optional }
            );
            routes.MapRoute(
                name: "Management",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Management", action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}
