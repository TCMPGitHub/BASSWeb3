using System.Web.Http;
using System.Configuration;

namespace BASSWEBV3.App_Start
{
    public static class WebApiConfig
    {
<<<<<<< HEAD

		public static void Register(HttpConfiguration config)
		{

			// Web API routes
			//config.MapHttpAttributeRoutes();
			config.Routes.MapHttpRoute(
=======
		public static void Register(HttpConfiguration config)
        {
            // Web API routes
            //config.MapHttpAttributeRoutes();
            config.Routes.MapHttpRoute(
>>>>>>> 108e65727d6ed079b44a7df7639105e481e2a6d9
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{action}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

        }
    }
}
