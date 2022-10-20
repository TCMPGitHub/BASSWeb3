using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Data.SqlClient;
using System.Data;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using Telerik.Documents.SpreadsheetStreaming;
using Kendo.Mvc.Export;
using Newtonsoft.Json;
using System.IO;
using System.Web;
using System.Runtime.Serialization.Json;
using System.Text;
using NPOI.SS.UserModel;
using NPOI.HSSF.Util;
using NPOI.HSSF.UserModel;
using NPOI.SS.Util;
using static BassWebV3.DataAccess.BassConstants;
using BassWebV3.ViewModels;
using BassIdentityManagement.Entities;
using BassIdentityManagement.Data;

namespace BassWebV3.Controllers
{
    [RoutePrefix("Reports")]
    public class ReportsController : AbstractBassController
    {
        // GET: /Reports/
        [Route]
        [HttpGet]
        public ActionResult Index()
        {
            if (!CurrentUser.CanAccessReports)
            {
                return RedirectToAction("Index", "Home");
            }

            ViewBag.ControllerID = ControllerID.Reports;
            ViewBag.IsAppViewOnly = CurrentUser.ViewBenefitOnly;
            //RecordPageLoad(CurrentUser.UserID);
            DateTime now = DateTime.Now;
            var startDate = new DateTime(now.Year, now.Month, 1);
            var endDate = (new DateTime(now.Year, now.Month, 1)).AddMonths(1).AddDays(-1);
            return View(new ReportsIndex { FromDate = startDate, ToDate = endDate, BfWorkerID = CurrentUser.UserID });
        }

        public FileResult ExportExcel([DataSourceRequest]DataSourceRequest request, string data)
        {
            dynamic options = JsonConvert.DeserializeObject(HttpUtility.UrlDecode(data));
            var fromdate = Convert.ToDateTime(options.FromDate.Value);
            var todate = Convert.ToDateTime(options.ToDate.Value);
            var sstring = options.BfWorkerIDs.Value;  //benefit worker IDs
            var productivities = GetProductivityReport(fromdate, todate, sstring) as IEnumerable<ProductivityReportRowDetail>;
            var usersName = productivities.Select(s => s.BenefitWorkerName).ToList();
            //List<string> bfusers = null;
            //if (sstring != null && sstring.ToString().Contains(","))
            //{
            //    bfusers = new List<string>(sstring.Split(','));
            //}
            //else
            //{
            //    bfusers = new List<string>() { sstring.ToString() };
            //}

            //get all benefit user name
            //var usersName = db.Users.Where(u => bfusers.Contains(u.UserID.ToString())).Select(s => new { BenefitWorkerName = s.LastName + ", " + s.FirstName + " " + s.MiddleName ?? "" }).ToList();

            var displayString = string.Empty;
            if (usersName != null && usersName.Count() > 0)
            {
                displayString = "[" + string.Join<string>("],[", usersName/*.Select(s => s.BenefitWorkerName*/) + "]";
            }

            //Create new Excel workbook
            var workbook = new HSSFWorkbook();
            IFont font1 = workbook.CreateFont();
            font1.FontHeightInPoints = 11;
            font1.Boldweight = (short)FontBoldWeight.Bold;
            font1.Color = HSSFColor.DarkBlue.Index;

            IFont font2 = workbook.CreateFont();
            font2.FontHeightInPoints = 11;
            font2.Boldweight = (short)FontBoldWeight.Bold;
            font2.Color = HSSFColor.Green.Index;

            HSSFCellStyle style = workbook.CreateCellStyle() as HSSFCellStyle;
            style.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.WrapText = true;
            style.SetFont(font1);
            style.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            HSSFCellStyle style2 = workbook.CreateCellStyle() as HSSFCellStyle;
            style2.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Center;
            style2.VerticalAlignment = VerticalAlignment.Center;
            style2.WrapText = true;
            style2.SetFont(font2);
            style2.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            //Create new Excel sheet
            var sheet = workbook.CreateSheet("Productivity");

            var title = displayString + " " + fromdate.ToString("MM/dd/yyyy") + " - " + todate.ToString("MM/dd/yyyy");

            //create header rows
            for (var i1 = 0; i1 < 4; i1++)
            {
                var headerRow = sheet.CreateRow(i1);
                for (int i = 0; i < 39; i++) { headerRow.CreateCell(i); }
            }

            //first header row
            var cra = new NPOI.SS.Util.CellRangeAddress(0, 3, 0, 0);
            sheet.AddMergedRegion(cra);
            var cell = sheet.GetRow(0).GetCell(0);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("App. YYYY-MM");
            cell.CellStyle = style;

            cra = new NPOI.SS.Util.CellRangeAddress(0, 3, 1, 1);
            sheet.AddMergedRegion(cra);
            cell = sheet.GetRow(0).GetCell(1);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("Benefit Worker Name");
            cell.CellStyle = style;

            cra = new NPOI.SS.Util.CellRangeAddress(0, 0, 2, 38);
            sheet.AddMergedRegion(cra);
            cell = sheet.GetRow(0).GetCell(2);
            cell.SetCellType(CellType.String);
            cell.SetCellValue(title);
            cell.CellStyle = style2;

            //second header row
            var cra1 = new NPOI.SS.Util.CellRangeAddress(1, 1, 2, 10);
            sheet.AddMergedRegion(cra1);
            var cell1 = sheet.GetRow(1).GetCell(2);
            cell1.SetCellType(CellType.String);
            cell1.SetCellValue("Offender Info");
            cell1.CellStyle = style;

            cra1 = new NPOI.SS.Util.CellRangeAddress(1, 1, 11, 38);
            sheet.AddMergedRegion(cra1);
            cell1 = sheet.GetRow(1).GetCell(11);
            cell1.SetCellType(CellType.String);
            cell1.SetCellValue("Notes In Timeframe");
            cell1.CellStyle = style;

            //third header row
            var cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 2, 2);
            sheet.AddMergedRegion(cra2);
            var cell2 = sheet.GetRow(2).GetCell(2);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("CDCR#");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 3, 3);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(3);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("EPRD");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 4, 4);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(4);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Screening Date");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 5, 7);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(5);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Application Date");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 8, 10);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(8);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("App/Note Discrepancy");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 11, 11);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(11);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Case Assigned");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 12, 12);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(12);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Face to Face");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 13, 13);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(13);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("TCMP Chrono");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 14, 14);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(14);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Case Mgmt.");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 15, 15);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(15);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Status Check / Update");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 16, 16);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(16);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("CTR File Rev.");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 17, 17);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(17);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("MEDC File Rev.");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 18, 20);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(18);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("MediCal");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 21, 23);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(21);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("SSI");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 24, 26);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(24);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("VA");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 27, 27);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(27);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("SNP Refused");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 28, 28);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(28);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("SNP Other");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 29, 29);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(29);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("CID Created");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 30, 30);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(30);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("CID Delivd.");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 31, 31);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(31);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Outcome Letter");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 32, 32);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(32);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Telphone Interview");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 33, 33);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(33);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Exit Interview");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 34, 34);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(34);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Release County");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 3, 35, 35);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(35);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Release To");
            cell2.CellStyle = style;

            cra2 = new NPOI.SS.Util.CellRangeAddress(2, 2, 36, 38);
            sheet.AddMergedRegion(cra2);
            cell2 = sheet.GetRow(2).GetCell(36);
            cell2.SetCellType(CellType.String);
            cell2.SetCellValue("Apply Facility");
            cell2.CellStyle = style;
            //last header row
            var cra3 = new NPOI.SS.Util.CellRangeAddress(2, 3, 5, 5);
            sheet.AddMergedRegion(cra3);
            var cell3 = sheet.GetRow(3).GetCell(5);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Medi-Cal");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 6, 6);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(6);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("SSI");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 7, 7);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(7);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("VA");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 8, 8);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(8);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Medi");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 9, 9);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(9);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("SSI");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 10, 10);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(10);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("VA");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 18, 18);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(18);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Code");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 19, 19);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(19);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("APP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 20, 20);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(20);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("BNP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 21, 21);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(21);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Code");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 22, 22);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(22);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("APP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 23, 23);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(23);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("BNP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 24, 24);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(24);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Code");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 25, 25);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(25);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("APP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 26, 26);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(26);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("BNP");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 36, 36);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(36);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("Medi");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 37, 37);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(37);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("SSI");
            cell3.CellStyle = style;

            cra3 = new NPOI.SS.Util.CellRangeAddress(3, 3, 38, 38);
            sheet.AddMergedRegion(cra3);
            cell3 = sheet.GetRow(3).GetCell(38);
            cell3.SetCellType(CellType.String);
            cell3.SetCellValue("VA");
            cell3.CellStyle = style;
            sheet.SetAutoFilter(new CellRangeAddress(3, 3, 0, 38));
            //set columns's width
            sheet.SetColumnWidth(0, 10 * 256);
            sheet.SetColumnWidth(1, 20 * 256);
            sheet.SetColumnWidth(2, 10 * 256);
            sheet.SetColumnWidth(3, 10 * 256);
            sheet.SetColumnWidth(4, 10 * 256);
            sheet.SetColumnWidth(5, 10 * 256);
            sheet.SetColumnWidth(6, 10 * 256);
            sheet.SetColumnWidth(7, 10 * 256);
            sheet.SetColumnWidth(8, 5 * 256);
            sheet.SetColumnWidth(9, 5 * 256);
            sheet.SetColumnWidth(10, 5 * 256);
            sheet.SetColumnWidth(11, 5 * 256);
            sheet.SetColumnWidth(12, 5 * 256);
            sheet.SetColumnWidth(13, 5 * 256);
            sheet.SetColumnWidth(14, 5 * 256);
            sheet.SetColumnWidth(15, 5 * 256);
            sheet.SetColumnWidth(16, 5 * 256);
            sheet.SetColumnWidth(17, 5 * 256);
            sheet.SetColumnWidth(18, 5 * 256);
            sheet.SetColumnWidth(19, 5 * 256);
            sheet.SetColumnWidth(20, 5 * 256);
            sheet.SetColumnWidth(21, 5 * 256);
            sheet.SetColumnWidth(22, 5 * 256);
            sheet.SetColumnWidth(23, 5 * 256);
            sheet.SetColumnWidth(24, 5 * 256);
            sheet.SetColumnWidth(25, 5 * 256);
            sheet.SetColumnWidth(26, 5 * 256);
            sheet.SetColumnWidth(27, 5 * 256);
            sheet.SetColumnWidth(28, 5 * 256);
            sheet.SetColumnWidth(29, 5 * 256);
            sheet.SetColumnWidth(30, 5 * 256);
            sheet.SetColumnWidth(31, 10 * 256);
            sheet.SetColumnWidth(32, 10 * 256);
            sheet.SetColumnWidth(33, 10 * 256);
            sheet.SetColumnWidth(34, 10 * 256);
            sheet.SetColumnWidth(35, 10 * 256);
            sheet.SetColumnWidth(36, 8 * 256);
            sheet.SetColumnWidth(37, 8 * 256);
            sheet.SetColumnWidth(38, 8 * 256);

            //(Optional) freeze the header row so it is not scrolled
            sheet.CreateFreezePane(39, 4, 39, 4);
            int rowNumber = 4;
            //Populate the sheet with values from the grid data
            foreach (var item in productivities)
            {
                //Create a new row
                var row = sheet.CreateRow(rowNumber++);
                row.CreateCell(0, CellType.String).SetCellValue(item.AppDate);
                row.CreateCell(1, CellType.String).SetCellValue(item.BenefitWorkerName);
                row.CreateCell(2, CellType.String).SetCellValue(item.CDCRNum);
                row.CreateCell(3, CellType.String).SetCellValue(item.EPRD);
                row.CreateCell(4, CellType.String).SetCellValue(item.ScreeningDate);
                row.CreateCell(5, CellType.String).SetCellValue(item.MediCalDate.HasValue ? item.MediCalDate.Value.ToString("MM-dd-yyyy") : "");
                row.CreateCell(6, CellType.String).SetCellValue(item.SsiDate.HasValue ? item.SsiDate.Value.ToString("MM-dd-yyyy") : "");
                row.CreateCell(7, CellType.String).SetCellValue(item.VaDate.HasValue ? item.VaDate.Value.ToString("MM-dd-yyyy") : "");
                row.CreateCell(8, CellType.Numeric).SetCellValue(item.MediCalDiscrepancy ? 1 : 0);
                row.CreateCell(9, CellType.Numeric).SetCellValue(item.SsiDiscrepancy ? 1 : 0);
                row.CreateCell(10, CellType.Numeric).SetCellValue(item.VaDiscrepancy ? 1 : 0);
                row.CreateCell(11, CellType.Numeric).SetCellValue(item.CaseAssigned);
                row.CreateCell(12, CellType.Numeric).SetCellValue(item.FaceToFace);
                row.CreateCell(13, CellType.Numeric).SetCellValue(item.TcmpChrono);
                row.CreateCell(14, CellType.Numeric).SetCellValue(item.CaseManagement);
                row.CreateCell(15, CellType.Numeric).SetCellValue(item.StatusCheckOrUpdate);
                row.CreateCell(16, CellType.Numeric).SetCellValue(item.CentralFileReview);
                row.CreateCell(17, CellType.Numeric).SetCellValue(item.MedicalFileReview);
                row.CreateCell(18, CellType.String).SetCellValue(item.MediCalCode);
                row.CreateCell(19, CellType.Numeric).SetCellValue(item.MediCalSubmission);
                row.CreateCell(20, CellType.Numeric).SetCellValue(item.MediCalBnp);
                row.CreateCell(21, CellType.String).SetCellValue(item.SSICode);
                row.CreateCell(22, CellType.Numeric).SetCellValue(item.SsiSubmission);
                row.CreateCell(23, CellType.Numeric).SetCellValue(item.SSIBnp);
                row.CreateCell(28, CellType.String).SetCellValue(item.VACode);
                row.CreateCell(25, CellType.Numeric).SetCellValue(item.VaSubmission);
                row.CreateCell(26, CellType.Numeric).SetCellValue(item.VABnp);
                row.CreateCell(27, CellType.Numeric).SetCellValue(item.ServicesNotProvidedRefused);
                row.CreateCell(28, CellType.Numeric).SetCellValue(item.ServicesNotProvidedOther);
                row.CreateCell(29, CellType.Numeric).SetCellValue(item.CidCreated);
                row.CreateCell(30, CellType.String).SetCellValue(item.CidDelivered);
                row.CreateCell(31, CellType.String).SetCellValue(item.OutcomeLetter);
                row.CreateCell(32, CellType.String).SetCellValue(item.TelInterview);
                row.CreateCell(33, CellType.String).SetCellValue(item.ExtInterview);
                row.CreateCell(34, CellType.String).SetCellValue(item.County);
                row.CreateCell(35, CellType.String).SetCellValue(item.ReleaseTo);
                row.CreateCell(36, CellType.String).SetCellValue(item.MediCalFa);
                row.CreateCell(37, CellType.String).SetCellValue(item.SSIFa);
                row.CreateCell(38, CellType.String).SetCellValue(item.VAFa);
            }

            HSSFCellStyle style1 = workbook.CreateCellStyle() as HSSFCellStyle;
            style1.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Right;
            style1.VerticalAlignment = VerticalAlignment.Center;
            style1.WrapText = true;
            style1.SetFont(font1);
            style1.FillForegroundColor = (short)HSSFColor.BlueGrey.Index;
            style1.FillBackgroundColor = (short)HSSFColor.BlueGrey.Index;

            var rowTotal = sheet.CreateRow(rowNumber);
            for (int i = 0; i < 39; i++) { rowTotal.CreateCell(i); }

            var formular = "SUM(D5:D" + (rowNumber - 1).ToString() + ")";
            var cra4 = new NPOI.SS.Util.CellRangeAddress(rowNumber, rowNumber, 0, 1);
            sheet.AddMergedRegion(cra4);
            var celltotal = sheet.GetRow(rowNumber).GetCell(0);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue("Total:");
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(2);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Count().ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(11);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.CaseAssigned).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(12);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.FaceToFace).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(13);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.TcmpChrono).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(14);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.CaseManagement).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(15);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.StatusCheckOrUpdate).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(16);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.CentralFileReview).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(17);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.MedicalFileReview).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(19);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.MediCalSubmission).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(20);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.MediCalBnp).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(22);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.SsiSubmission).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(23);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.SSIBnp).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(25);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.VaSubmission).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(26);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.VABnp).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(27);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.ServicesNotProvidedRefused).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(28);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.ServicesNotProvidedOther).ToString());
            celltotal.CellStyle = style1;

            celltotal = sheet.GetRow(rowNumber).GetCell(29);
            celltotal.SetCellType(CellType.String);
            celltotal.SetCellValue(productivities.Sum(s => s.CidCreated).ToString());
            celltotal.CellStyle = style1;

            //Write the workbook to a memory stream
            MemoryStream output = new MemoryStream();
            workbook.Write(output);
            //Return the result to the end user
            return File(output.ToArray(), "application/vnd.ms-excel", "ProductivityRpt.xls");
        }

        public FileResult ExportBWExcel([DataSourceRequest]DataSourceRequest request, string data)
        {
            dynamic options = JsonConvert.DeserializeObject(HttpUtility.UrlDecode(data));
            var fromdate = Convert.ToDateTime(options.FromDate.Value);
            var todate = Convert.ToDateTime(options.ToDate.Value);
            var sstring = options.BfWorkerIDs.Value;  //benefit worker IDs
            var productivities = GetBWProductivityReport(fromdate, todate, sstring) as IEnumerable<BWProductivityReportData>;
            var usersName = productivities.Select(w => w.BenefitWorkerName).Distinct().ToList();
            //List<string> bfusers = null;
            //if (sstring != null && sstring.ToString().Contains(","))
            //{
            //    bfusers = new List<string>(sstring.Split(','));
            //}
            //else
            //{
            //    bfusers = new List<string>() { sstring.ToString() };
            //}

            //get all benefit user name
            //var usersName = db.Users.Where(u => bfusers.Contains(u.UserID.ToString())).Select(s => new { BenefitWorkerName = s.LastName + ", " + s.FirstName + " " + s.MiddleName ?? "" }).ToList();

            var displayString = string.Empty;
            if (usersName != null && usersName.Count() > 0)
            {
                displayString = "[" + string.Join("],[", usersName) + "]";
                //displayString = "[" + string.Join<string>("],[", usersName.Select(s => s.BenefitWorkerName)) + "]";
            }

            //Create new Excel workbook
            var workbook = new HSSFWorkbook();
            IFont font1 = workbook.CreateFont();
            font1.FontHeightInPoints = 11;
            font1.Boldweight = (short)FontBoldWeight.Bold;
            font1.Color = HSSFColor.DarkBlue.Index;

            IFont font2 = workbook.CreateFont();
            font2.FontHeightInPoints = 10;
            font2.Boldweight = (short)FontBoldWeight.Bold;
            font2.Color = HSSFColor.Green.Index;

            HSSFCellStyle style = workbook.CreateCellStyle() as HSSFCellStyle;
            style.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.WrapText = true;
            style.SetFont(font1);
            style.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            HSSFCellStyle style1 = workbook.CreateCellStyle() as HSSFCellStyle;
            style1.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Right;
            style1.VerticalAlignment = VerticalAlignment.Center;
            style1.WrapText = true;
            style1.SetFont(font1);
            style1.FillForegroundColor = (short)HSSFColor.BlueGrey.Index;
            style1.FillBackgroundColor = (short)HSSFColor.BlueGrey.Index;

            HSSFCellStyle style2 = workbook.CreateCellStyle() as HSSFCellStyle;
            style2.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Center;
            style2.VerticalAlignment = VerticalAlignment.Center;
            style2.WrapText = true;
            style2.SetFont(font1);
            style2.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            HSSFCellStyle style3 = workbook.CreateCellStyle() as HSSFCellStyle;
            style3.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Left;
            style3.VerticalAlignment = VerticalAlignment.Top;
            style3.WrapText = true;
            style3.SetFont(font1);
            style3.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            //Create new Excel sheet
            var sheet = workbook.CreateSheet("BWProductivity");

            var title = displayString + " " + fromdate.ToString("MM/dd/yyyy") + " - " + todate.ToString("MM/dd/yyyy");

            //first header row
            var row = sheet.CreateRow(0);
            row.RowStyle = style2;
            row.CreateCell(0, CellType.String).SetCellValue("");
            row.CreateCell(1, CellType.String).SetCellValue("ClientName");
            row.CreateCell(2, CellType.String).SetCellValue("CDCRNum");
            row.CreateCell(3, CellType.String).SetCellValue("Medi-cal Amount");
            row.CreateCell(4, CellType.String).SetCellValue("SSI Amount");
            row.CreateCell(5, CellType.String).SetCellValue("VA Amount");
            row.CreateCell(6, CellType.String).SetCellValue("SNP/REFUSE Amount");
            row.CreateCell(7, CellType.String).SetCellValue("Medi-cal BNP Amount");
            row.CreateCell(8, CellType.String).SetCellValue("SSI BNP Amount");
            row.CreateCell(9, CellType.String).SetCellValue("VA BNP Amount");

            foreach (var cell in row.Cells)
            {
                cell.CellStyle = style;
            }
            //sheet.SetAutoFilter(new CellRangeAddress(0, 0, 0, 0));
            //set columns's width
            sheet.SetColumnWidth(0, 20 * 256);
            sheet.SetColumnWidth(1, 20 * 256);
            sheet.SetColumnWidth(2, 20 * 256);
            sheet.SetColumnWidth(3, 20 * 256);
            sheet.SetColumnWidth(4, 20 * 256);
            sheet.SetColumnWidth(5, 20 * 256);
            sheet.SetColumnWidth(6, 20 * 256);
            sheet.SetColumnWidth(7, 20 * 256);
            sheet.SetColumnWidth(8, 20 * 256);
            sheet.SetColumnWidth(9, 20 * 256);

            //(Optional) freeze the header row so it is not scrolled
            //sheet.CreateFreezePane(7, 1, 7, 1);
            var arrayBWID = productivities.Select(s => s.BenefitWorkerId).Distinct().ToArray();
            var count = arrayBWID.Length;
            var firstrow = 1;
            int rowNumber = 1;

            for (int line = 0; line < count; line++)
            {
                var ptvr = productivities.Where(w => w.BenefitWorkerId == arrayBWID[line]).OrderBy(o => o.CDCRNum);
                var total = ptvr.Count();
                var headerrow = sheet.CreateRow(rowNumber++);
                headerrow.CreateCell(0, CellType.String).SetCellValue("");
                headerrow.CreateCell(1, CellType.String).SetCellValue("");
                headerrow.CreateCell(2, CellType.String).SetCellValue(ptvr.Count());
                headerrow.CreateCell(3, CellType.String).SetCellValue(ptvr.Sum(s => s.MCTotal));
                headerrow.CreateCell(4, CellType.String).SetCellValue(ptvr.Sum(s => s.SSITotal));
                headerrow.CreateCell(5, CellType.String).SetCellValue(ptvr.Sum(s => s.VATotal));
                headerrow.CreateCell(6, CellType.String).SetCellValue(ptvr.Sum(s => s.SNPRTotal));
                headerrow.CreateCell(7, CellType.String).SetCellValue(ptvr.Sum(s => s.MediCalBnp));
                headerrow.CreateCell(8, CellType.String).SetCellValue(ptvr.Sum(s => s.SSIBnp));
                headerrow.CreateCell(9, CellType.String).SetCellValue(ptvr.Sum(s => s.VATotal));
                var name = ptvr.Select(s => s.BenefitWorkerName).FirstOrDefault();
                headerrow.CreateCell(0, CellType.String).SetCellValue(name);
                foreach (var item in ptvr)
                {
                    //Create a new row
                    var row1 = sheet.CreateRow(rowNumber++);
                    row1.CreateCell(0, CellType.String).SetCellValue("");
                    row1.CreateCell(1, CellType.String).SetCellValue(item.ClientName);
                    row1.CreateCell(2, CellType.String).SetCellValue(item.CDCRNum);
                    row1.CreateCell(3, CellType.String).SetCellValue(item.MCTotal);
                    row1.CreateCell(4, CellType.String).SetCellValue(item.SSITotal);
                    row1.CreateCell(5, CellType.String).SetCellValue(item.VATotal);
                    row1.CreateCell(6, CellType.String).SetCellValue(item.SNPRTotal);
                    row1.CreateCell(7, CellType.String).SetCellValue(item.MediCalBnp);
                    row1.CreateCell(8, CellType.String).SetCellValue(item.SSIBnp);
                    row1.CreateCell(9, CellType.String).SetCellValue(item.VABnp);
                }

                var footerrow = sheet.CreateRow(rowNumber++);
                footerrow.CreateCell(0, CellType.String).SetCellValue("");
                footerrow.CreateCell(1, CellType.String).SetCellValue("Group Total:");
                footerrow.CreateCell(2, CellType.String).SetCellValue(ptvr.Count());
                footerrow.CreateCell(3, CellType.String).SetCellValue(ptvr.Sum(s => s.MCTotal));
                footerrow.CreateCell(4, CellType.String).SetCellValue(ptvr.Sum(s => s.SSITotal));
                footerrow.CreateCell(5, CellType.String).SetCellValue(ptvr.Sum(s => s.VATotal));
                footerrow.CreateCell(6, CellType.String).SetCellValue(ptvr.Sum(s => s.SNPRTotal));
                footerrow.CreateCell(7, CellType.String).SetCellValue(ptvr.Sum(s => s.MediCalBnp));
                footerrow.CreateCell(8, CellType.String).SetCellValue(ptvr.Sum(s => s.SSIBnp));
                footerrow.CreateCell(9, CellType.String).SetCellValue(ptvr.Sum(s => s.VATotal));
                firstrow = rowNumber;
            }

            var groups = productivities.OrderByDescending(o => o.BenefitWorkerId).ToList();
            int fcount = 1;
            int ecount = 0;
            for (int i = 0; i < arrayBWID.Length; i++)
            {
                var plist = productivities.Where(w => w.BenefitWorkerId == arrayBWID[i]).Count();
                ecount += (plist + 2);
                var region = new CellRangeAddress(fcount, ecount, 0, 0);
                sheet.AddMergedRegion(region);
                sheet.GroupRow(fcount, ecount - 1);
                sheet.SetRowGroupCollapsed(fcount, true);
                fcount = (ecount + 1);
            }

            int mergedRegions = sheet.NumMergedRegions;
            for (int regs = 0; regs < mergedRegions; regs++)
            {
                CellRangeAddress mRegionInx = sheet.GetMergedRegion(regs);

                for (int currentRegion = mRegionInx.FirstRow; currentRegion < mRegionInx.LastRow; currentRegion++)
                {
                    var currentRow = sheet.GetRow(currentRegion);
                    currentRow.Cells[0].CellStyle = style3;
                }
            }

            var row2 = sheet.CreateRow(rowNumber);
            row2.RowStyle = style1;
            row2.CreateCell(0, CellType.String).SetCellValue("Report Total:");
            row2.CreateCell(1, CellType.String).SetCellValue("");
            row2.CreateCell(2, CellType.String).SetCellValue(productivities.Count());
            row2.CreateCell(3, CellType.String).SetCellValue(productivities.Sum(s => s.MCTotal));
            row2.CreateCell(4, CellType.String).SetCellValue(productivities.Sum(s => s.SSITotal));
            row2.CreateCell(5, CellType.String).SetCellValue(productivities.Sum(s => s.VATotal));
            row2.CreateCell(6, CellType.String).SetCellValue(productivities.Sum(s => s.SNPRTotal));
            row2.CreateCell(7, CellType.String).SetCellValue(productivities.Sum(s => s.MediCalBnp));
            row2.CreateCell(8, CellType.String).SetCellValue(productivities.Sum(s => s.SSIBnp));
            row2.CreateCell(9, CellType.String).SetCellValue(productivities.Sum(s => s.VATotal));

            foreach (var cell in row2.Cells)
            {
                cell.CellStyle = style1;
            }
            //Write the workbook to a memory stream
            MemoryStream output = new MemoryStream();
            workbook.Write(output);
            //Return the result to the end user
            return File(output.ToArray(), "application/vnd.ms-excel", "BWProductivityRpt.xls");
        }
        [HttpPost]
        public FileStreamResult ExportServer(string model, string data)
        {
            FileStreamResult fileStreamResult = null;
            DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(ExportColumnSettings));
            var obj = HttpUtility.UrlDecode(model);
            MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(obj));
            var obj1 = (ExportColumnSettings)ser.ReadObject(ms);
            var columnsData = JsonConvert.DeserializeObject<IList<ExportColumnSettings>>(HttpUtility.UrlDecode(model));
            dynamic options = JsonConvert.DeserializeObject(HttpUtility.UrlDecode(data));
            SpreadDocumentFormat exportFormat = SpreadDocumentFormat.Xlsx;
            Action<ExportCellStyle> cellStyle = new Action<ExportCellStyle>(ChangeCellStyle);
            Action<ExportRowStyle> rowStyle = new Action<ExportRowStyle>(ChangeRowStyle);
            Action<ExportColumnStyle> columnStyle = new Action<ExportColumnStyle>(ChangeColumnStyle);

            string fileName = string.Format("{0}.{1}", options.title, options.format);
            string mimeType = Helpers.GetMimeType(exportFormat);
            DateTime start = options.FromDate;
            DateTime end = options.ToDate;
            try
            {
                Stream exportStream = GetInmatesReport(start, end, 0).ToXlsxStream(columnsData, (string)options.title.ToString(), cellStyleAction: cellStyle, rowStyleAction: rowStyle, columnStyleAction: columnStyle);

                fileStreamResult = new FileStreamResult(exportStream, mimeType);
                fileStreamResult.FileDownloadName = fileName;
                fileStreamResult.FileStream.Seek(0, SeekOrigin.Begin);
            }
            catch (Exception ex)
            {
                string message = ex.Message;
            }
            //Stream exportStream = exportFormat == SpreadDocumentFormat.Xlsx ?
            //    GetFacilityOutlookReport(DateTime.Now).ToXlsxStream(columnsData, (string)options.title.ToString(), cellStyleAction: cellStyle, rowStyleAction: rowStyle, columnStyleAction: columnStyle) :
            //    GetFacilityOutlookReport(DateTime.Now).ToCsvStream(columnsData);
            return fileStreamResult;
        }

        public ActionResult FilterBW_read(string BfWorkerIDs)
        {
            if (!string.IsNullOrEmpty(BfWorkerIDs))
            {
                var Ids = BfWorkerIDs.Split(',').ToList();
               // var query = db.Users.Where(w => Ids.Contains(w.UserID.ToString())).Select(s => new { BenefitWorkerName = s.LastName + ", " + s.FirstName.Substring(0, 1) + "." }).Distinct().ToList();
                return Json(null, JsonRequestBehavior.AllowGet);
            }
            return Json(null, JsonRequestBehavior.AllowGet);
        }
        public JsonResult GetAllUsers()
        {
            string query = @"SELECT UserID, (LastName + ', ' + FirstName + ' ' + ISNULL(MiddleName, ''))BenefitWorkerName FROM dbo.[User]
                          WHERE IsBenefitWorker = 1 AND IsActive = 1 ORDER BY LastName";
            var result = SqlHelper.ExecuteCommands<AssignmentUserList>(query, 1);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        private void ChangeCellStyle(ExportCellStyle e)
        {
            bool isHeader = e.Row == 0;
            SpreadCellFormat format = new SpreadCellFormat
            {
                ForeColor = isHeader ? SpreadThemableColor.FromRgb(50, 54, 58) : SpreadThemableColor.FromRgb(214, 214, 217),
                IsItalic = true,
                VerticalAlignment = SpreadVerticalAlignment.Center,
                WrapText = true,
                Fill = SpreadPatternFill.CreateSolidFill(isHeader ? new SpreadColor(93, 227, 0) : new SpreadColor(50, 54, 58))
            };
            e.Cell.SetFormat(format);
        }
        private void ChangeRowStyle(ExportRowStyle e)
        {
            e.Row.SetHeightInPixels(e.Index == 0 ? 80 : 30);
        }

        private void ChangeColumnStyle(ExportColumnStyle e)
        {
            double width = e.Name == "Product name" || e.Name == "Category Name" ? 250 : 100;
            e.Column.SetWidthInPixels(width);
        }

        public ActionResult InmatsData_Read([DataSourceRequest] DataSourceRequest request, DateTime FromDate, DateTime ToDate)
        {
            return Json(GetInmatesReport(FromDate, ToDate, 0).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        public ActionResult InmatsDetailsData_Read([DataSourceRequest] DataSourceRequest request, DateTime FromDate, DateTime ToDate)
        {
            return Json(GetInmatesDetailsReport(FromDate, ToDate, 1).OrderBy(o => o.CDCRNum).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        public ActionResult BWProductivityData_Read([DataSourceRequest] DataSourceRequest request, DateTime FromDate, DateTime ToDate, string BfWorkerIDs)
        {
            return Json(GetBWProductivityReport(FromDate, ToDate, BfWorkerIDs).OrderBy(o => o.BenefitWorkerId).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        public ActionResult InmatesProductivityData_Read([DataSourceRequest] DataSourceRequest request, DateTime FromDate, DateTime ToDate, string BfWorkerIDs)
        {
            return Json(GetProductivityReport(FromDate, ToDate, BfWorkerIDs).OrderByDescending(o => o.AppDate).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        public ActionResult FacilityOutlookReportData_Read([DataSourceRequest] DataSourceRequest request, DateTime FromDate)
        {
            return Json(GetFacilityOutlookReport(FromDate).OrderBy(o => o.FacilityName).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }

        private List<FacilityOutlookReportData> GetFacilityOutlookReport(DateTime FromDate)
        {
            List<ParameterInfo> paramList = new List<ParameterInfo> {
                    { new ParameterInfo { ParameterName="ReportDate", ParameterValue=FromDate } }
                };
            var results = SqlHelper.GetRecords<FacilityOutlookReportData>("spFacilityOutlookRpt", paramList).ToList();
            return results;
        }

        private List<ProductivityReportRowDetail> GetProductivityReport(DateTime FromDate, DateTime ToDate, string BfWorkerIDs)
        {
            List<ParameterInfo> ParamList = new List<ParameterInfo>
            {
               new ParameterInfo {ParameterName="FromDate", ParameterValue=FromDate },
               new ParameterInfo {ParameterName="ToDate", ParameterValue=ToDate },
               new ParameterInfo {ParameterName="BfWorkerIDs", ParameterValue=BfWorkerIDs }
            };
            var result = SqlHelper.GetRecords<ProductivityReportRowDetail>("spRptProductivityV3", ParamList).ToList();
            return result;
        }

        private List<InmatesReleaseReportData> GetInmatesReport(DateTime StartDate, DateTime EndDate, int Details)
        {
            List<InmatesReleaseReportData> InmatesDataList = new List<InmatesReleaseReportData>();
            List<ParameterInfo> paramList = new List<ParameterInfo> {
                 new ParameterInfo { ParameterName = "FromDate", ParameterValue = StartDate },
                 new ParameterInfo{ ParameterName = "ToDate", ParameterValue = EndDate },
                 new ParameterInfo { ParameterName = "Details", ParameterValue = Details }
            };
            var result = SqlHelper.GetRecords<InmatesReleaseReportData>("spRptInmatesRelease", paramList).ToList();
            return result;
        }

        public ActionResult FilterInmatesDetailsFa_read()
        {
            var query = @"SELECT FacilityID, (OrgCommonID + '-' + Name)NameWithCode, Abbr FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0";
            var result = SqlHelper.ExecuteCommands<Facility>(query, 1);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        private List<InmatesReleaseDetailsReportData> GetInmatesDetailsReport(DateTime StartDate, DateTime EndDate, int Details)
        {
            List<ParameterInfo> ParamList = new List<ParameterInfo> {
              new ParameterInfo { ParameterName="FromDate", ParameterValue=StartDate },
              new ParameterInfo { ParameterName="ToDate", ParameterValue=EndDate },
              new ParameterInfo { ParameterName="Details", ParameterValue=Details }
             };
            var result = SqlHelper.GetRecords<InmatesReleaseDetailsReportData>("spRptInmatesRelease", ParamList).ToList();
            return result;
        }

        private List<BWProductivityReportData> GetBWProductivityReport(DateTime FromDate, DateTime ToDate, string BfWorkerIDs)
        {
            List<ParameterInfo> ParamList = new List<ParameterInfo>
            {
                new ParameterInfo { ParameterName="FromDate", ParameterValue=FromDate },
                new ParameterInfo { ParameterName="ToDate", ParameterValue=ToDate },
                new ParameterInfo { ParameterName="BfWorkerIDs", ParameterValue=BfWorkerIDs }
            };
            var result = SqlHelper.GetRecords<BWProductivityReportData>("spRptBWProductivityV3", ParamList).ToList();
            return result;
        }
    }
}