using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public enum CasePriority
    {
        longTermMedCare,
        Hospice,
        AssistedLiving,
        HivPos,
        ChronicIllness,
        EOP,
        PhysDisabled,
        DevDisabled,
        CCCMS,
        Elderly,
        DSH
    }
    public enum ReviewStatusCode
    {
        NotFlagged = 0, Flagged = 1, ReviewComplete = 2
    }
    public class DerivedSomsData
    {
        //public int PID { get; set; }
        public string CDCRNum { get; set; }
        public int? CustodyFacilityID { get; set; }
        public DateTime? SomsReleaseDate { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public int? GenderID { get; set; }
        public string Housing { get; set; }
        public string SSN { get; set; }
        public DateTime FileDate { get; set; }
        public DateTime? DOB { get; set; }
        public bool EOP { get; set; }
        public bool CCCMS { get; set; }
        public bool PC290 { get; set; }
        public bool PC457 { get; set; }
        public bool DevDisabled { get; set; }
        public bool PhysDisabled { get; set; }
        public bool MedPlacement { get; set; }
        public bool SSI { get; set; }
        public bool Lifer { get; set; }
        public int? ReleaseCountyID { get; set; }
        public string ParoleUnit { get; set; }
        public string ParoleAgent { get; set; }
    }
    public class InmateProfileData
    {
        public int EpisodeID { get; set; }
        public string CDCRNum { get; set; }
        public int OffenderID { get; set; }
        public bool SomsDataExists { get; set; }
        public bool SomsFlagged { get; set; }
        public bool CaseAssigned { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public bool PC290 { get; set; }
        public bool PC457 { get; set; }
        public bool USVet { get; set; }
        public int ReviewStatus { get; set; }
        public string SSN { get; set; }
        public DateTime? DOB { get; set; }
        public int? GenderID { get; set; }
        public bool LongTermMedCare { get; set; }
        public bool Hospice { get; set; }
        public bool AssistedLiving { get; set; }
        public bool HIVPos { get; set; }
        public bool ChronicIllness { get; set; }
        public bool EOP { get; set; }
        public bool CCCMS { get; set; }
        public bool Elderly { get; set; }
        public bool PhysDisabled { get; set; }
        public bool DevDisabled { get; set; }
        public bool DSH { get; set; }
        public bool SSI { get; set; }
        public bool VRSS { get; set; }
        public bool Lifer { get; set; }
        public int? ReleaseCountyID { get; set; }
        public int? CustodyFacilityID { get; set; }
        public DateTime? ScreeningDate { get; set; }
        public bool AuthToRepresent { get; set; }
        public bool ReleaseOfInfoSigned { get; set; }
        public int? EpisodeAcpDshTypeID { get; set; }
        public int? EpisodeMdoSvpTypeID { get; set; }
        public int? EpisodeMedReleaseTypeID { get; set; }
        public bool? ReleasedToPRCS { get; set; }
        public DateTime? CIDServiceRefusalDate { get; set; }
        public DateTime ReferralDate { get; set; }
        public DateTime? ReleaseDate { get; set; }
        public string Housing { get; set; }
        public string ParoleUnit { get; set; }
        public string ParoleAgent { get; set; }
        public int? BenefitWorkerID { get; set; }
        public int? ScreeningDateSetByUserID { get; set; }
        public DateTime? _CIDServicePlanDate_Disabled { get; set; }
        public int? DestinationID { get; set; }
        public bool? MedPlacement { get; set; }
        public DateTime FileDate { get; set; }
        public bool? CalFreshRef { get; set; }
        public bool? CalWorksRef { get; set; }
        public bool? FosterYouth { get; set; }
        public bool? DHCSEligibility { get; set; }
        public DateTime? DHCSEligibilityDate { get; set; }
        public string BenefitWorkerName { get; set; }
        public string EpisodeAddress { get; set; }
        public string EpisodeAddressCity { get; set; }
        public string EpisodeAddressState { get; set; }
        public string EpisodeAddressZip { get; set; }
        public bool? EpisodeAddressUpdated { get; set; }

        //public bool Unassign { get; set; }
        //public bool EditingEnabled { get; set; }
        //public bool EditingDisabledBeyondScreening { get; set; }
        //public bool ShowAddCase { get; set; }
        //public bool ShowTotalRefusalDate { get; set; }
        //public bool CalFreshRefYes { get; set; }
        //public bool CalFreshRefNo { get; set; }
        //public bool CalWorksRefYes { get; set; }
        //public bool CalWorksRefNo { get; set; }

        //public bool DHCSEligibilityYes { get; set; }
        //public bool DHCSEligibilityNo { get; set; }

        //public string DHCSEligibilityDate { get; set; }
        //public int SelectedEpisodeID { get; set; }


        //public bool DisableOpeningVaApp { get; set; }
        //public bool DisableOpeningAllApps { get; set; } 
        //public bool DestinationDateNeeded { get; set; }
    }
    public class Offender
    {
        [Key]
        public int OffenderID { get; set; }
        [StringLength(25)]
        public string MiddleName { get; set; }
        public bool PC290 { get; set; }
        public bool PC457 { get; set; }
        public bool USVet { get; set; }
        public int ReviewStatus { get; set; }
        [StringLength(35)]
        public string FirstName { get; set; }
        [StringLength(35)]
        public string LastName { get; set; }
        [StringLength(11)]
        public string SSN { get; set; }
        public DateTime? DOB { get; set; }
        public int GenderID { get; set; }
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
        public bool MedPlacement { get; set; }
        public bool DSH { get; set; }
        public bool SSI { get; set; }
        public bool VRSS { get; set; }
        public int PID { get; set; }
        public int? SomsUploadId { get; set; }
        public DateTime? InitialImportDate { get; set; }
    }
   
}
