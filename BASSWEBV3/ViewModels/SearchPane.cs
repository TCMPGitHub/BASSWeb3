using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;

namespace BassWebV3.ViewModels
{
    public class SearchPane
    {
        public List<Facility> AllFacilities { get; set; }
        public List<ReleasePeriod> AllReleasePeriods { get; set; }
        public string SelectedReleasePeriod { get; set; }
        public int? SelectedFacilityID { get; set; }

        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }

        public string SearchString { get; set; }

        public bool IncludeLifers { get; set; }
        public bool IncludeActiveOnly { get; set; }
        public bool NoQualifiers { get; set; }
        public bool LongTermMedCare { get; set; }
        public bool Hospice { get; set; }
        public bool AssistedLiving { get; set; }
        public bool HIVPos { get; set; }
        public bool ChronicIllness { get; set; }
        public bool EOP { get; set; }
        public bool PhysDisabled { get; set; }
        public bool DevDisabled { get; set; }
        public bool CCCMS { get; set; }
        public bool Elderly { get; set; }
        public bool USVet { get; set; }
        public bool DSH { get; set; }
        public bool SSI { get; set; }
        //public bool VRSS { get; set; }



        public SearchPane() { }

        //public SearchPane(List<Facility> facilities)
        //{
        //    //var query = facilities.Where(f => !f.Disabled).Select(f => new { Value = f.FacilityID, Text = f.NameWithCode }).OrderBy(x => x.Text);

           
        //    IncludeLifers = true;
        //    IncludeActiveOnly = false;
        //}
    }

    public class UserWorkStatus
    {
        public int StatusID { get; set; }
        public int UserID { get; set; }
        public int? FacilityID { get; set; }
        public int SupervisorID { get; set; }
        public string UserName { get; set; }
        public string Facility { get; set; }
        public string LocationNote { get; set; }
        public string CheckedOutNote { get; set; }
        public bool Traveling { get; set; }
        public string CheckInDateTime { get; set; }
        public string CheckOutDateTime { get; set; }
    }
}