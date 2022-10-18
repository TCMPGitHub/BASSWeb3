using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using BassIdentityManagement.Entities;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using System.Collections;
using System.IO;
using NPOI.HSSF.UserModel;
using Newtonsoft.Json;
using NPOI.SS.UserModel;
using NPOI.HSSF.Util;
using Kendo.Mvc.Export;
using System.Reflection;
using BassIdentityManagement.Data;
using BassWebV3.ViewModels;
using BassWebV3.ViewModels.CaseAssignment;
using static BassWebV3.DataAccess.BassConstants;

namespace BassWebV3.Controllers
{
    public class CaseAssignmentController : AbstractBassController
    {
        [Route("~/CaseAssignment")]
        [HttpGet]
        public ActionResult Index()
        {
            ViewBag.ControllerID = ControllerID.CaseAssignment;
            ViewBag.CurrentUser = (ApplicationUser)Session["CurrentUser"];
            ViewBag.IsAppViewOnly = CurrentUser.ViewBenefitOnly;
            var query = @"SELECT FacilityID, (OrgCommonID + '-' + Name)NameWithCode, Abbr FROM dbo.Facility WHERE ISNULL(Disabled, 0) = 0";
            var result = SqlHelper.ExecuteCommands<Facility>(query, 1).ToList();
            var datePeriod = new List<ReleasePeriod>()
            {
                new ReleasePeriod {  PeriodID =1 , Abbr= "0,30", Period="0-30 days" },
                new ReleasePeriod {  PeriodID =2 , Abbr= "31,60", Period="31-60 days" },
                new ReleasePeriod {  PeriodID =3 , Abbr= "61,90", Period="61-90 days" },
                new ReleasePeriod {  PeriodID =4 , Abbr= "91,120", Period="91-120 days" },
                new ReleasePeriod {  PeriodID =5 , Abbr= "0,182", Period="6 months" },
                new ReleasePeriod {  PeriodID =6 , Abbr= "0,365", Period="1 year" }
            };
            //RecordPageLoad(CurrentUser.UserID);
            return View(new SearchPane { FromDate = DateTime.Now, ToDate = DateTime.Now.AddDays(180),
                IncludeActiveOnly = !CurrentUser.CanAccessReports,
                AllFacilities = result, AllReleasePeriods = datePeriod
            });
        }

        [ChildActionOnly]
        public ActionResult DefaultAssignmentPane()
        {
            return Content("");
            //return PartialView("_AssignmentPane", new AssignmentPaneViewModel(db.Users));
        }

        public ActionResult CaseAssignmentForAllRead([DataSourceRequest] DataSourceRequest request, DateTime? FromDate, DateTime? ToDate, 
            int Facility, string MaybeCDCR, int Lifer, string Qualifier)
        {
            List<CaseAssignmentData> retList = GetAllCassAssignments(FromDate, ToDate, Facility, MaybeCDCR, Lifer, Qualifier);
            return Json(retList.OrderByDescending(o => o.HighestCasePriority).ToDataSourceResult(request), JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public ActionResult Excel_Export_Save(string contentType, string base64, string fileName)
        {
            var fileContents = Convert.FromBase64String(base64);

            return File(fileContents, contentType, fileName);
        }

        private List<CaseAssignmentData> GetAllCassAssignments(DateTime? FromDate, DateTime? ToDate,
             int Facility, string MayBeCDCR, int Lifer, string Qualifier)
        {
            List<BassIdentityManagement.Data.ParameterInfo> parameters = new List<BassIdentityManagement.Data.ParameterInfo>();
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "FromDate", ParameterValue = FromDate });
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "ToDate", ParameterValue = ToDate });
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "Facility", ParameterValue = Facility });
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "MaybeCDCR", ParameterValue = MayBeCDCR });
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "Lifer", ParameterValue = Lifer });
            parameters.Add(new BassIdentityManagement.Data.ParameterInfo() { ParameterName = "CurrentUserID", ParameterValue = CurrentUser.UserID });
            var results = SqlHelper.GetRecords<CaseAssignmentData>("spCaseAssignmentsv3", parameters).ToList();
            if (!string.IsNullOrEmpty(Qualifier))
            {
                var list = Qualifier.Split(',').Select(x => int.Parse(x));
                results = results.Where(w => list.Contains<int>(w.HighestCasePriority)).ToList();
            }
            return results;
        }
      
        [HttpPost]
        public ActionResult SaveGridData(List<int> ArrayOfEpisoddeID, int BenifitWorkerID)
        {
            var count = 0;
            if (ArrayOfEpisoddeID != null)
            {
                count = ArrayOfEpisoddeID.Count();
                string queryall = string.Empty;
                
                foreach (var epID in ArrayOfEpisoddeID)
                {
                    var query = string.Format(@"IF Exists(SELECT 1 FROM dbo.CaseAssignment WHERE EpisodeID  = {1})
   UPDATE dbo.CaseAssignment SET LatestAssignment = null WHERE EpisodeID  = {1}
INSERT INTO dbo.CaseAssignment (BenefitWorkerID, EpisodeID,AssignedDateTime, ActionBy, LatestAssignment) VALUES ({0}, {1}, GetDate(), {2}, 1)",
                            BenifitWorkerID, epID, CurrentUser.UserID);
                    queryall = queryall + query;
                }

                var result = SqlHelper.ExecuteCommand(queryall, 1);
            }
            //Returns how many records was posted
            return Json(new { count = count });
        }

        [HttpPost]
        public ActionResult UpdateGridData(List<int> ArrayOfEpisoddeID, int BenifitWorkerID)
        {
            var count = ArrayOfEpisoddeID.Count();
            if (ArrayOfEpisoddeID != null && count > -1)
            {
                var query = string.Format(@"UPDATE dbo.CaseAssignment SET UnAssignedDateTime = GetDate() WHERE BenefitWorkerID ={0} AND EpisodeID in ({1})",
                    BenifitWorkerID, string.Join(",", ArrayOfEpisoddeID));
                var result = SqlHelper.ExecuteCommand(query, 1);
            }
            //Returns how many records was posted
            return Json(new { count = count });
        }
        public ActionResult FilterBW_read()
        {
            var query = @"SELECT UserID, (LastName + ', ' + FirstName + ' ' + ISNULL(MiddleName, ''))BenefitWorkerName FROM dbo.[User]
                          WHERE IsBenefitWorker = 1 AND IsActive = 1
                           ORDER BY LastName DESC";
            var result = SqlHelper.ExecuteCommands<AssignmentUserList>(query, 1);                
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public JsonResult GetBWUsers(string text)
        {
            string query = string.Empty;
            if (CurrentUser.IsBenefitWorker && !CurrentUser.CanAccessReports)
            {
                query = string.Format(@"SELECT UserID, (LastName + ', ' + FirstName + ' ' + ISNULL(MiddleName, ''))BenefitWorkerName FROM dbo.[User]
                          WHERE UserID = {0}", CurrentUser.UserID);               
            }
            else
            {
                query = string.Format(@"SELECT UserID, (LastName + ', ' + FirstName + ' ' + ISNULL(MiddleName, ''))BenefitWorkerName FROM dbo.[User]
                          WHERE IsBenefitWorker = 1 AND IsActive = 1 AND (LastName + ', ' + FirstName + ' ' + ISNULL(MiddleName, '')) like {0}
                           ORDER BY LastName DESC", "'%" + text + "%'");
            }
            var result = SqlHelper.ExecuteCommands<AssignmentUserList>(query, 1);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult CaseAssignmentUnassign([DataSourceRequest] DataSourceRequest request,
            CaseAssignmentData assignment)
        {
            if (ModelState.IsValid)
            {
                var query = string.Format(@"UPDATE dbo.CaseAssignment SET UnAssignedDateTime = GetDate() WHERE CaseAssignmentID ={0}",
                    assignment.CaseAssignmentID);
                var result = SqlHelper.ExecuteCommand(query, 1);
            }

            return Json(new[] { assignment }.ToDataSourceResult(request, ModelState), JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult Assign(AssignmentPane submission)
        {
            if (ModelState.IsValid)
            {
                var selectedEpisodeIDs = submission.EpisodeCheckboxes.Where(c => c.IsChecked).Select(c => c.EpisodeID);
                
                return Json(new { success = true });
            }
            return ErrorsJson(ModelStateErrors());
        }


        public FileResult Export([DataSourceRequest]DataSourceRequest request, string data)
        {
            dynamic options = JsonConvert.DeserializeObject(HttpUtility.UrlDecode(data));
            var fromdate = Convert.ToDateTime(options.FromDate.Value);
            var todate = Convert.ToDateTime(options.ToDate.Value);
            var facility = Convert.ToInt32(options.Facility.Value);
            var cdcr = Convert.ToString(options.MaybeCDCR.Value);
            var lifer = Convert.ToInt32(options.Lifer.Value);
            var qualifier = Convert.ToString(options.Qualifier.Value);
            List<CaseAssignmentData> assignedCases = GetAllCassAssignments(fromdate, todate, facility, cdcr, lifer, qualifier);
            // var strArray = (new CaseAssignmentForAll()).GetType().GetProperties().Select(s => s.Name).ToArray();

            //Create new Excel workbook
            var workbook = new HSSFWorkbook();
            //Create new Excel sheet
            var sheet = workbook.CreateSheet("CaseAssignments");

            var font = workbook.CreateFont();
            font.FontHeightInPoints = 11;
            font.FontName = "Calibri";
            font.Boldweight = (short)NPOI.SS.UserModel.FontBoldWeight.Bold;

            //(Optional) set the width of the columns
            sheet.SetColumnWidth(0, 10 * 256);
            sheet.SetColumnWidth(1, 10 * 256);
            sheet.SetColumnWidth(2, 40 * 256);
            sheet.SetColumnWidth(3, 10 * 256);
            sheet.SetColumnWidth(4, 20 * 256);
            sheet.SetColumnWidth(5, 20 * 256);
            sheet.SetColumnWidth(6, 10 * 256);
            sheet.SetColumnWidth(7, 10 * 256);
            sheet.SetColumnWidth(8, 10 * 256);
            sheet.SetColumnWidth(9, 10 * 256);
            sheet.SetColumnWidth(10, 10 * 256);
            sheet.SetColumnWidth(11, 10 * 256);
            sheet.SetColumnWidth(12, 10 * 256);
            sheet.SetColumnWidth(13, 10 * 256);
            sheet.SetColumnWidth(14, 10 * 256);
            sheet.SetColumnWidth(15, 40 * 256);

            IFont font1 = workbook.CreateFont();
            font1.FontHeightInPoints = 11;
            font1.Boldweight = (short)FontBoldWeight.Bold;
            font1.Color = HSSFColor.DarkBlue.Index;

            HSSFCellStyle style = workbook.CreateCellStyle() as HSSFCellStyle;
            style.Alignment = NPOI.SS.UserModel.HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.SetFont(font1);
            style.FillBackgroundColor = (short)HSSFColor.Grey80Percent.Index;

            //Create a header row
            var headerRow = sheet.CreateRow(0);
            //Set the column names in the header row
            headerRow.CreateCell(0).SetCellValue("Qualifier");
            headerRow.CreateCell(1).SetCellValue("CDCR#");
            headerRow.CreateCell(2).SetCellValue("Offender Name");
            headerRow.CreateCell(3).SetCellValue("Facility Name");
            headerRow.CreateCell(4).SetCellValue("Release Date");
            headerRow.CreateCell(5).SetCellValue("Housing");
            headerRow.CreateCell(6).SetCellValue("HIV/AIDS");
            headerRow.CreateCell(7).SetCellValue("Chronic Illnes");
            headerRow.CreateCell(8).SetCellValue("CCCMS");
            headerRow.CreateCell(9).SetCellValue("EOP");
            headerRow.CreateCell(10).SetCellValue("Disability");
            headerRow.CreateCell(11).SetCellValue("Elderly");
            headerRow.CreateCell(12).SetCellValue("DHS");
            headerRow.CreateCell(13).SetCellValue("US Vet");
            headerRow.CreateCell(14).SetCellValue("Lifer");
            headerRow.CreateCell(15).SetCellValue("Assigned To");

            foreach (var cell in headerRow.Cells)
            {
                cell.CellStyle = style;
            }
            //(Optional) freeze the header row so it is not scrolled
            sheet.CreateFreezePane(0, 1, 0, 1);
            int rowNumber = 1;
            //Populate the sheet with values from the grid data
            foreach (var item in assignedCases)
            {
                //Create a new row
                var row = sheet.CreateRow(rowNumber++);
                IDataFormat dataFormatCustom = workbook.CreateDataFormat();

                var casePriority = "";
                switch (item.HighestCasePriority)
                {
                    case 1:
                        casePriority = "USVet"; break;
                    case 2:
                        casePriority = "Elderly"; break;
                    case 3:
                        casePriority = "CCCMS"; break;
                    case 4:
                        casePriority = "DevDisabled"; break;
                    case 5:
                        casePriority = "PhysDisabled"; break;
                    case 6:
                        casePriority = "EOP"; break;
                    case 7:
                        casePriority = "DSH"; break;
                    case 8:
                        casePriority = "ChronicIllness"; break;
                    case 9:
                        casePriority = "HIVPos"; break;
                    case 10:
                        casePriority = "AssistedLiving"; break;
                    case 11:
                        casePriority = "Hospice"; break;
                    case 12:
                        casePriority = "LongTermMedCare"; break;
                    default:
                        casePriority = ""; break;
                }

                row.CreateCell(0, CellType.String).SetCellValue(casePriority);
                row.CreateCell(1, CellType.String).SetCellValue(item.CDCRNum);
                row.CreateCell(2, CellType.String).SetCellValue(item.OffenderName);
                row.CreateCell(3, CellType.String).SetCellValue(item.FacilityName);
                //row.CreateCell(4).CellStyle.DataFormat = dataFormatCustom.GetFormat("MM/dd/yyyy");
                row.CreateCell(4, CellType.String).SetCellValue(item.ReleaseDate.ToString("MM/dd/yyyy"));
                row.CreateCell(5, CellType.String).SetCellValue(item.Housing);
                row.CreateCell(6, CellType.Boolean).SetCellValue(item.HIVPos);
                row.CreateCell(7, CellType.Boolean).SetCellValue(item.ChronicIllness);
                row.CreateCell(8, CellType.Boolean).SetCellValue(item.CCCMS);
                row.CreateCell(9, CellType.Boolean).SetCellValue(item.EOP);
                row.CreateCell(10, CellType.Boolean).SetCellValue(item.DevDisabled);
                row.CreateCell(11, CellType.Boolean).SetCellValue(item.Elderly);
                row.CreateCell(12, CellType.Boolean).SetCellValue(item.DSH);
                row.CreateCell(13, CellType.Boolean).SetCellValue(item.USVet);
                row.CreateCell(14, CellType.Boolean).SetCellValue(item.Lifer);
                row.CreateCell(15, CellType.String).SetCellValue(item.BenefitWorkerName);
            }

            //Write the workbook to a memory stream
            MemoryStream output = new MemoryStream();
            workbook.Write(output);
            //Return the result to the end user
            return File(output.ToArray(), "application/vnd.ms-excel", "CaseAssignments.xls");
            //"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "CaseAssignments.xlsx");
            //"GridExcelExport.xlsx");     //Suggested file name in the "Save as" dialog which will be displayed to the end user
        }
        public FileResult Export1(string model, string data)
        {
            var columnsData = JsonConvert.DeserializeObject<IList<ExportColumnSettings>>(HttpUtility.UrlDecode(model)).ToList();
            dynamic options = JsonConvert.DeserializeObject(HttpUtility.UrlDecode(data));
            var fromdate = Convert.ToDateTime(options.FromDate.Value);
            var todate = Convert.ToDateTime(options.ToDate.Value);
            var facility = options.Facility.Value;
            var cdcr = options.MaybeCDCR.Value;
            var lifer = options.Lifer.Value;
            var qualifier = options.Qualifier;
            var models = GetAllCassAssignments(fromdate, todate, facility, cdcr, lifer, qualifier) as IEnumerable<CaseAssignmentData>;
            byte[] bytes = WriteExcel(models, columnsData.Where(x => x.Hidden == false && x.Field != null).Select(s => s.Field).ToArray());
            return File(bytes, "application/vnd.ms-excel", "CaseAssignments.xls");

            var workbook = new HSSFWorkbook();

            //Create new Excel sheet
            var sheet = workbook.CreateSheet();
            var headerRow = sheet.CreateRow(0);
            for (int i = 0; i < columnsData.Count(); i++)
            {
                if (columnsData[i].Hidden == true)
                    continue;
                if (columnsData[i].Field == null)
                    continue;
                var index = int.Parse(columnsData[i].Width.Value.ToString());
                sheet.SetColumnWidth(i, index * 256);
                headerRow.CreateCell(i).SetCellValue(columnsData[i].Title);
            }

            //(Optional) freeze the header row so it is not scrolled
            sheet.CreateFreezePane(0, 1, 0, 1);
            int rowNumber = 1;

            //Populate the sheet with values from the grid data
            foreach (var item in models)
            {
                //Create a new row
                var row = sheet.CreateRow(rowNumber++);

                //Set values for the cells
                row.CreateCell(0).SetCellValue(item.HighestCasePriority);
                row.CreateCell(1).SetCellValue(item.CDCRNum);
                row.CreateCell(2).SetCellValue(item.OffenderName);
                row.CreateCell(3).SetCellValue(item.FacilityName);
                row.CreateCell(4).SetCellValue(item.ReleaseDate);
                row.CreateCell(5).SetCellValue(item.Housing);
                row.CreateCell(6).SetCellValue(item.HIVPos);
                row.CreateCell(7).SetCellValue(item.ChronicIllness);
                row.CreateCell(8).SetCellValue(item.CCCMS);
                row.CreateCell(9).SetCellValue(item.EOP);
                row.CreateCell(10).SetCellValue(item.DevDisabled);
                row.CreateCell(11).SetCellValue(item.Elderly);
                row.CreateCell(12).SetCellValue(item.DSH);
                row.CreateCell(13).SetCellValue(item.USVet);
                row.CreateCell(14).SetCellValue(item.Lifer);
                row.CreateCell(15).SetCellValue(item.BenefitWorkerName);
            }

            //Write the workbook to a memory stream
            MemoryStream output = new MemoryStream();
            workbook.Write(output);


            return File(output.ToArray(), "application/vnd.ms-excel", "CaseAssignments.xls");
            //return File(output, "application/vnd.ms-excel",
            //    "CaseAssignments.xlsx");
        }

        public byte[] WriteExcel(IEnumerable data, string[] columns)
        {
            MemoryStream output = new MemoryStream();
            HSSFWorkbook workbook = new HSSFWorkbook();
            ISheet sheet = workbook.CreateSheet();
            IFont headerFont = workbook.CreateFont();
            headerFont.Boldweight = (short)FontBoldWeight.Bold;
            ICellStyle headerStyle = workbook.CreateCellStyle();
            headerStyle.SetFont(headerFont);
            headerStyle.Alignment = HorizontalAlignment.Center;

            //(Optional) freeze the header row so it is not scrolled
            sheet.CreateFreezePane(0, 1, 0, 1);
            IEnumerator foo = data.GetEnumerator();
            foo.MoveNext();
            Type t = foo.Current.GetType();
            IRow header = sheet.CreateRow(0);
            PropertyInfo[] properties = t.GetProperties();

            int colIndex = 0;
            for (int i = 0; i < properties.Length; i++)
            {
                if (columns.Contains(properties[i].Name))
                {
                    ICell cell = header.CreateCell(colIndex);
                    cell.CellStyle = headerStyle;
                    cell.SetCellValue(properties[i].Name);
                    colIndex++;
                }
            }

            int rowIndex = 0;
            foreach (object o in data)
            {
                colIndex = 0;
                IRow row = sheet.CreateRow(rowIndex + 1);
                for (int i = 0; i < properties.Length; i++)
                {
                    if (columns.Contains(properties[i].Name))
                    {
                        row.CreateCell(colIndex).SetCellValue(properties[i].GetValue(o, null).ToString());
                        colIndex++;
                    }
                }
                rowIndex++;
            }

            workbook.Write(output);
            return output.ToArray();
        }

    }
}