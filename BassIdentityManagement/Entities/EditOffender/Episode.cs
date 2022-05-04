using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class Episode
    {
        [Key]
        public int EpisodeID { get; set; }
        public int OffenderID { get; set; }
        public int? ReleaseCountyID { get; set; }
        [StringLength(32)]
        public string ParoleUnit { get; set; }
        [StringLength(96)]
        public string ParoleAgent { get; set; }
        public DateTime? ScreeningDate { get; set; }
        public bool AuthToRepresent { get; set; }
        public bool ReleaseOfInfoSigned { get; set; }
        public bool ApplyForSSI { get; set; }
        public bool ApplyForVA { get; set; }
        public bool ApplyForMediCal { get; set; }
        public int? EpisodeAcpDshTypeID { get; set; }
        public int? EpisodeMdoSvpTypeID { get; set; }
        public int? EpisodeMedReleaseTypeID { get; set; }
        public bool? ReleasedToPRCS { get; set; }
        public DateTime? CIDServiceRefusalDate { get; set; }
        [StringLength(6)]
        public string CDCRNum { get; set; }
        public DateTime? ReferralDate { get; set; }
        public DateTime? ReleaseDate { get; set; }
        [StringLength(25)]
        public string Housing { get; set; }
        public int? CustodyFacilityID { get; set; }
        public bool Lifer { get; set; }
        public int? ScreeningDateSetByUserID { get; set; }
        public bool _Hold_Disabled { get; set; }
        public int? DestinationID { get; set; }
        public DateTime FileDate { get; set; }
        public DateTime? SomsReleaseDate { get; set; }
        public DateTime? InitialImportDate { get; set; }
        public int? SomsUploadId { get; set; }
        [StringLength(30)]
        public string MhStatus { get; set; }
        public bool? CalFreshRef { get; set; }
        public bool? CalWorksRef { get; set; }
        public bool? DHCSEligibility { get; set; }
        public DateTime? DHCSEligibilityDate { get; set; }
    }
}
