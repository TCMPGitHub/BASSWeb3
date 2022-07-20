using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class CaseAssignmentData
    {
        [Key]
        public int EpisodeID { get; set; }
        [Required]
        [Display(Name = "Release Date")]
        public DateTime ReleaseDate { get; set; }
        [Required]
        [Display(Name = "Offender Name"), StringLength(95)]
        public string OffenderName { get; set; }
        [Display(Name = "CaseAssignment ID")]
        public int? CaseAssignmentID { get; set; }
        [Display(Name = "BenefitWorker ID")]
        public int? BenefitWorkerID { get; set; }
        
        [Required]
        [Display(Name = "Priority")]
        public int HighestCasePriority { get; set; }
        [Display(Name = "BenefitWorker Name"), StringLength(75)]
        public string BenefitWorkerName { get; set; }
        [Required]
        [Display(Name = "Facility Name"), StringLength(25)]
        public string FacilityName { get; set; }
        [Display(Name = "Custody Facility ID")]
        public int? CustodyFacilityID { get; set; }
        [Required]
        [Display(Name = "CDCRNum"), StringLength(6)]
        public string CDCRNum { get; set; }
        [Required]
        [Display(Name = "Housing"), StringLength(25)]
        public string Housing { get; set; }
        [Required]
        [Display(Name = "CCCMS")]
        public bool CCCMS { get; set; }
        [Required]
        [Display(Name = "DSH")]
        public bool DSH { get; set; }
        [Required]
        [Display(Name = "USVet")]
        public bool USVet { get; set; }
        [Required]
        [Display(Name = "EOP")]
        public bool EOP { get; set; }
        [Required]
        [Display(Name = "ChronicIllness")]
        public bool ChronicIllness { get; set; }
        [Required]
        [Display(Name = "DevDisabled")]
        public bool DevDisabled { get; set; }
        [Required]
        [Display(Name = "Elderly")]
        public bool Elderly { get; set; }
        [Required]
        [Display(Name = "LongTermMedCare")]
        public bool LongTermMedCare { get; set; }
        [Required]
        [Display(Name = "HIVPos")]
        public bool HIVPos { get; set; }
        [Required]
        [Display(Name = "AssistedLiving")]
        public bool AssistedLiving { get; set; }
        [Required]
        [Display(Name = "PhysDisabled")]
        public bool PhysDisabled { get; set; }
        [Required]
        [Display(Name = "Hospice")]
        public bool Hospice { get; set; }
        [Required]
        [Display(Name = "Lifer")]
        public bool Lifer { get; set; }
        public string RedFlag { get; set; }
    }
}
    //public class AssignmentHistoryData
    //{
    //    public int ID { get; set; }
    //    public int EpisodeId { get; set; }
    //    public DateTime AssignmentDate { get; set; }
    //    public string SocialWorkerName { get; set; }
    //    public string ParoleAgentName { get; set; }
    //    public string PsychologistName { get; set; }
    //    public string PsychiatristName { get; set; }
    //    public string CaseManagerName { get; set; }
    //    public string AssignedBy { get; set; }
    //}
    
    //public class BenefitWorkerAssignedCase
    //{
    //    [Key]
    //    public int EpisodeID { get; set; }
    //    [Required]
    //    [Display(Name = "CDCRNum"), StringLength(6)]
    //    public string CDCRNum { get; set; }
    //    [Required]
    //    [Display(Name = "Offender Name"), StringLength(95)]
    //    public string ClientName { get; set; }
    //    [Display(Name = "MHClass"), StringLength(5)]
    //    public string MHClass { get; set; }
    //    [Display(Name = "Codes"), StringLength(20)]
    //    public string Codes { get; set; }
    //    [Display(Name = "Soms Release Date")]
    //    public DateTime? SomsReleaseDate { get; set; }
    //    [Required]
    //    [Display(Name = "Release Date")]
    //    public DateTime ReleaseDate { get; set; }
    //    [Display(Name = "Soms Custody Facility Name"), StringLength(100)]
    //    public string SomsCustFacilityName { get; set; }
    //    [Required]
    //    [Display(Name = "Custody Facility Name"), StringLength(100)]
    //    public string CustFacilityName { get; set; }
    //    [Required]
    //    [Display(Name = "Housing"), StringLength(25)]
    //    public string Housing { get; set; }
    //    [Required]
    //    [Display(Name = "Application"), StringLength(15)]
    //    public string Apps { get; set; }
    //    [Display(Name = "App Status"), StringLength(200)]
    //    public string AppStatus { get; set; }
    //    public string RedFlag { get; set; }
    //}
//}
