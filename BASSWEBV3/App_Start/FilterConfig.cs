using System.Web;
using System.Web.Mvc;

namespace BASSWEBV3
{
    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
        }

    }

    public class IpPropertyActionFilter : ActionFilterAttribute
    {
        public override void OnResultExecuting(ResultExecutingContext filterContext)
        {
            filterContext.Controller.ViewBag.IpProperty = "value";
        }
    }


}
