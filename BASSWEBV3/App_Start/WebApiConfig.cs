using System.Web.Http;
using System.Configuration;

namespace BASSWEBV3.App_Start
{
    public static class WebApiConfig
    {
		public static void Register(HttpConfiguration config)
        {
            // Web API routes
            //config.MapHttpAttributeRoutes();
            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{action}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

        }
    }
}
