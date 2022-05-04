using System;

namespace BassWebV3.ViewModels
{
    public class ApplicationReadonly
    {
        public int ApplicationID { get; set; }
        public int ApplicationTypeID { get; set; }
        public int EpisodeID { get; set; }
        public string CDCRNum { get; set; }
        public string ClientName { get; set; }
        public string ReleaseCountyName { get; set; }
        public bool? AgreesToApply { get; set; }
        public DateTime AppliedOrRefusedOnDate { get; set; }
        public string PhoneInterviewDate { get; set; }
        public string OutcomeDate { get; set; }
        public string OutCome { get; set; }
        public string ApplicationTypeName { get; set; }
        public string ApplicationOutComeName { get; set; }
        public string CustFacilityName { get; set; }
        public string ArchivedOnDate { get; set; }
        public bool HasPhoneInterview { get; set; }
        public bool HasBIC { get; set; }
        public string BICNum { get; set; }
        public string IssuedOnDate { get; set; }
        public bool RestoreEnabled { get; set; }
    }
}