using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace BassWebV3.ViewModels
{
    public enum ProgramStatus { Any = 1, Referral, ScreenedNoDisposition, Accepted, ServicesNotProvided }
    public class OffenderSearch
    {
        public int? SelectedSearchUser { get; set; }
        public ApplicationUser LoginUser { get; set; }
        public List<ActiveUserList> AllSearchUsers { get; set; }
        public int? SelectedSearchFacility { get; set; }
        public LoadedEpisode SelectEpisode { get; set; }
        public List<Facility> AllSearchFacilities { get; set; }
        public ProgramStatus ProgramStatus { get; set; }
        public string SearchString { get; set; }
        public int? SelectedSearchResult { get; set; }
        public string[] CaseNoteTypesWithServices { get; set; }
        public bool ShowGetMyCases { get; set; }
        public OffenderSearch() { }
        public OffenderSearch(List<ActiveUserList> BenefitWorkers, List<Facility> Facilities, List<CaseNoteType> CaseNoteTypes, ApplicationUser loggedInUser)
        {
            this.LoginUser = loggedInUser;
            AllSearchUsers = BenefitWorkers;
            AllSearchFacilities = Facilities;
            CaseNoteTypesWithServices = CaseNoteTypes.Select(s=>s.Name).ToArray();
            SelectedSearchResult = 1;
            ShowGetMyCases = (BenefitWorkers.Where(w=>w.UserID== loggedInUser.UserID).FirstOrDefault() != null);
        }
    }
}