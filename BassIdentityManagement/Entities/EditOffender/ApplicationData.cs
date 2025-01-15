using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class ApplicationFlags
    {
        public int EpisodeID { get; set; }
        public bool HasMediCalApp { get; set; }
        public bool HasSSIApp { get; set; }
        public bool HasVAApp { get; set; }
        public bool HasArchivedApps { get; set; }
        public bool ButtonEnable { get; set; }
        public bool IsVAInmate { get; set; }
    }
    public class ApplicationData
    {
        public int EpisodeID { get; set; }
        public int ApplicationID { get; set; }
        public int ApplicationTypeID { get; set; }
        public int? ApplicationOutcomeID { get; set; }
        public bool? AgreesToApply { get; set; }
        public DateTime? AppliedOrRefusedOnDate { get; set; }
        public DateTime? PhoneInterviewDate { get; set; }
        public DateTime? OutcomeDate { get; set; }
        public string BICNum { get; set; }
        public string CINNum { get; set; }
        public DateTime? IssuedOnDate { get; set; }
        public DateTime? ArchivedOnDate { get; set; }
        public int CreatedByUserID { get; set; }
        public int? CustodyFacilityId { get; set; }
        public int? SubmitCountyID { get; set; }
        public DateTime DateAction { get; set; }
        public DateTime? DHCSDate { get; set; }
        public bool IsEditable { get; set; }
    }

    public class ArchiveApplicationData
    {
        public int EpisodeID { get; set; }
        public int ApplicationID { get; set; }
        public int ApplicationTypeID { get; set; }
        public string ApplicationTypeName { get; set; }
        public DateTime? AppliedOrRefusedOnDate { get; set; }
        public DateTime? ArchivedOnDate { get; set; }
        public bool RestoreEnabled { get; set; }
    }

    public class ArchiveApplicationReadData
    {
        public int ApplicationID { get; set; }
        public int ApplicationTypeID { get; set; }
        public bool AgreesToApply { get; set; }
        public string ApplicationTypeName { get; set; }
        public DateTime? AppliedOrRefusedOnDate { get; set; }
        public DateTime? ArchivedOnDate { get; set; }
        public DateTime? PhoneInterviewDate { get; set; }
        public DateTime? IssuedOnDate { get; set; }
        public DateTime? OutcomeDate { get; set; }
        public string CustodyFacility { get; set; }
        public string Outcome { get; set; }
        public string BICNum { get; set; }
        public string CINNum { get; set; }
        public string SubmitCounty { get; set; }
    }
}
