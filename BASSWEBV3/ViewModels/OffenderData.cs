using BassIdentityManagement.Entities;
using System.Collections.Generic;
using static BassWebV3.DataAccess.BassConstants;

namespace BassWebV3.ViewModels
{
    public class OffenderData
    {
        public bool EditingEnabled { get; set; }
        public bool IsUnassignedCase { get; set; }
        public DerivedSomsData DerivedSomsData { get; set; }
        public InmateProfileData Inmate { get; set; }
        public List<Episodes> AllEpisodes { get; set; }
        public List<County> AllCounties { get; set; }
        public List<Facility> AllFacilities { get; set; }
        public List<ReleaseDateChanged> SomsReleaseDates { get; set; }
        public List<Gender> AllGenders { get; set; }
        public List<EpisodeAcpDshType> AllAcpDshTypes { get; set; }
        public List<EpisodeMdoSvpType> AllMdoSvpTypes { get; set; }
        public List<EpisodeMedReleaseType> AllMedReleaseTypes { get; set; }
        public List<LookUpTable> AllDestinationIDs { get; set; }
        //public List<ApplicationData> Apps { get; set; }
        //public ApplicationFlags AppFlags { get; set; }
        //public OffenderData() { }
        //public OffenderDate(InmateProfileData mainData, DerivedSomsData SomsData, List<County> AllCounties) { }
    }
    public class CaseNoteFiles
    {
        public int EpisodeID { get; set; }
        public bool CanEditNote { get; set; }
        public bool HideCaseNote { get; set; }
        public bool HideDocument { get; set; }
        public bool CanUploadFile { get; set; }
    }
}