using System.Web;
using System.Web.Optimization;

namespace BASSWEBV3
{
    public class BundleConfig
    {
        // For more information on bundling, visit http://go.microsoft.com/fwlink/?LinkId=301862
        public static void RegisterBundles(BundleCollection bundles)
        {
            bundles.IgnoreList.Ignore("*.unobtrusive-ajax.min.js", OptimizationMode.WhenDisabled);
            bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
                        "~/Scripts/jquery-{version}.js"));

            bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
                           "~/Scripts/jquery-3.3.1.min.js",
                           "~/Scripts/jquery-migrate-3.3.0.min.js"));
            // Use the development version of Modernizr to develop with and learn from. Then, when you're
            // ready for production, use the build tool at http://modernizr.com to pick only the tests you need.
            bundles.Add(new ScriptBundle("~/bundles/modernizr").Include(
                        "~/Scripts/modernizr-2.8.3.js"));

            bundles.Add(new ScriptBundle("~/bundles/kendo").Include(
                      "~/Scripts/Telerik/2019.3.11/kendo.all.min.js",
                      "~/Scripts/Telerik/2019.3.11/kendo.aspnetmvc.min.js",
                      "~/Scripts/Telerik/2019.3.11/jszip.min.js",
                      "~/Scripts/dist/clipboard.min.js"));
            bundles.Add(new ScriptBundle("~/bundles/bass").Include("~/Scripts/Bass/Bass.js"));

            bundles.Add(new StyleBundle("~/Content/css")
                   .Include("~/Content/site.css", new CssRewriteUrlTransform())
                   .Include("~/Content/Styles/Bass.css", new CssRewriteUrlTransform())
                   .Include("~/Content/Telerik/2019.3.11/kendo.common.min.css", new CssRewriteUrlTransform())
                   .Include("~/Content/Telerik/2019.3.11/kendo.common.bootstrap.min.css", new CssRewriteUrlTransform())
                   .Include("~/Content/Telerik/2019.3.11/kendo.bootstrap.min.css", new CssRewriteUrlTransform()));
        }
    }
}
