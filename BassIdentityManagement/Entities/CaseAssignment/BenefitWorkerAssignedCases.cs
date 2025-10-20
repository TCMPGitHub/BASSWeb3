using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class BenefitWorkerAssignedCase
    {
        [Key]
        public int EpisodeID { get; set; }
        [Required]
        [Display(Name = "CDCRNum"), StringLength(6)]
        public string CDCRNum { get; set; }
        [Required]
        [Display(Name = "Offender Name"), StringLength(95)]
        public string ClientName { get; set; }
        [Display(Name = "MHClass"), StringLength(5)]
        public string MHClass { get; set; }
        [Display(Name = "Codes"), StringLength(20)]
        public string Codes { get; set; }
        [Display(Name = "Soms Release Date")]
        public DateTime? SomsReleaseDate { get; set; }
        [Required]
        [Display(Name = "Release Date")]
        public DateTime ReleaseDate { get; set; }
        [Display(Name = "Soms Custody Facility Name"), StringLength(100)]
        public string SomsCustFacilityName { get; set; }
        [Required]
        [Display(Name = "Custody Facility Name"), StringLength(100)]
        public string CustFacilityName { get; set; }
        [Required]
        [Display(Name = "Housing"), StringLength(25)]
        public string Housing { get; set; }
        [Required]
        [Display(Name = "Days to Release"), StringLength(10)]
        public string DaytoRelease { get; set; }
        [Required]
        [Display(Name = "Application"), StringLength(15)]
        public string Apps { get; set; }
        [Display(Name = "App Status"), StringLength(200)]
        public string AppStatus { get; set; }
        public string RedFlag { get; set; }
        public string BICNum { get; set; }
        public string CINNum { get; set; }
        public string Outcome { get; set; }
        public DateTime? FaceToFaceDate { get; set; }
        public DateTime? ExitInterviewDate { get; set; }
    }
}
