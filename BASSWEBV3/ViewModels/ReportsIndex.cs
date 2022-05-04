using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace BassWebV3.ViewModels
{
    public enum ReportType { InmatesReleased, Productivity }
    public class ReportsIndex : IValidatableObject
    {
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public int? BfWorkerID { get; set; }
        public ReportType ReportType { get; set; }

        public int? SelectedBenefitWorkerID { get; set; }
        public IEnumerable<SelectListItem> AllBenefitWorkers { get; private set; }

        public ReportsIndex()
        {
            ReportType = ReportType.InmatesReleased;
        }


        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (FromDate != null && ToDate == null)
            {
                yield return new ValidationResult("Please enter both a \"From\" date and a \"To\" date, or leave both blank.", new[] { "FromDate" });
            }

            if (FromDate == null && ToDate != null)
            {
                yield return new ValidationResult("Please enter both a \"From\" date and a \"To\" date, or leave both blank.", new[] { "ToDate" });
            }
        }
    }
}