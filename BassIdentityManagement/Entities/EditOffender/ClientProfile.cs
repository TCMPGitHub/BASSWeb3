using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class ClientProfile
    {
        public int EpisodeId { get; set; }
        [Required]
        public string CDCRNumber { get; set; }
        public int? CountyId { get; set; }
        public int? ComplexId { get; set; }
        public int? EthnicityId { get; set; }
        public int? PID { get; set; }
        [Required]
        public int GenderID { get; set; }
        public string POB { get; set; }        //place of birth
        [Required]
        public string LastName { get; set; }
        [Required]
        public string FirstName { get; set; }
        public string MidName { get; set; }
        public DateTime? DOB { get; set; }     //date of birth
        public string SSN { get; set; }
        public string Alias { get; set; }
        public string SignificantOtherStatus { get; set; }
        public int? MHLevelOfService { get; set; }
        public DateTime? InTakeDate { get; set; }
        public DateTime? CaseBankedDate { get; set; }
        public string CaseReferral { get; set; }
        public DateTime? ParoleDisChargeDate { get; set; }
        public DateTime? ReleaseDate { get; set; }
        public int? SelectedLocationId { get; set; }
        public string ParoleUnit { get; set; }
        public bool PC290 { get; set; }
        public bool PC457 { get; set; }
        public bool Lifer { get; set; }
        public bool USVet { get; set; }      
        public bool? IsConvictedOfStalking { get; set; }
        //public bool? IsSeriousViolentOffender { get; set; }
        public string CaseClosureReasonID { get; set; }
        public DateTime? CaseClosureDate { get; set; }
        public DateTime? ISMIPReferredDate { get; set; }
        public DateTime? ISMIPEnrolledDate { get; set; }
        public DateTime? ISMIPClosedDate { get; set; }
        public DateTime? CMProgramStartDate { get; set; }
        public DateTime? CMProgramClosedDate { get; set; }
        public DateTime? MATProgramStartDate { get; set; }
        public DateTime? MATProgramClosedDate { get; set; }
        public DateTime? CMRPEStartDate { get; set; }
        public DateTime? CMRPEClosedDate { get; set; }
        public string ParoleAgent { get; set; }
        public DateTime? ASAMDate { get; set; }
        public int? AsamFileId { get; set; }
        public bool InclusionCriteriaMetYes { get; set; }
        public bool InclusionCriteriaMetNo { get; set; }
        public string ASAMComments { get; set; }
    }
    public class MatchClient
    {
        public int PID { get; set; }
        public int EpisodeId { get; set; }
        public string CDCRNumber { get; set; }
        //public string FirstName { get; set; }
        //public string LastName { get; set; }
        public string Name { get; set; }
        public string DOB { get; set; }
        public int MatchGender { get; set; }
        public DateTime? RealeaseDate { get; set; }
        public string CaseClosureDate { get; set; }
        public string CaseCloseReason { get; set; }
    }
    public class Complex
    {
        public int ComplexID { get; set; }
        public string ComplexDesc { get; set; }
    }

    public class Ethnicity
    {
        public int EthnicityID { get; set; }
        public string EthnicityDesc { get; set; }
    }
    //public class Gender
    //{
    //    public int GenderID { get; set; }
    //    public string Name { get; set; }
    //}
    public class SignificantOtherStatus
    {
        public string SignificantOtherStatusCode { get; set; }
        public string SignificantOtherStatusDesc { get; set; }
    }
    public class CaseClosureReason
    {
        public string CaseClosureReasonCode { get; set; }
        public string CaseClosureReasonDescShort { get; set; }
    }
    public class CaseReferralSource
    {
        public string CaseReferralSourceCode { get; set; }
        public string CaseReferralSourceDesc { get; set; }
    }
    public class ParoleMentalHealthLevelOfService
    {
        public int ParoleMentalHealthLevelOfServiceID { get; set; }
        public string ParoleMentalHealthLevelOfServiceDescShort { get; set; }
    }
    public class Location
    {
        public int LocationID { get; set; }
        public string LocationDesc { get; set; }
    }

    public class RptClientInfo
    {
        public string CDCRNum { get; set; }
        public string PAROLEENAME { get; set; }
        public string ParoleUnit { get; set; }
        public string ParoleRegion { get; set; }
        public string ParoleAgent { get; set; }
        public DateTime? ReleaseDate { get; set; }
        public bool PC290 { get; set; }
        public DateTime? DOB { get; set; }
        public string MhStatus { get; set; }
        public string PrintDate { get; set; }

    }
}
