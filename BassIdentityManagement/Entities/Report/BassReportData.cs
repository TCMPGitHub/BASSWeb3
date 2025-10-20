using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class InmatesReleaseReportData
    {
        [Key]
        public string FacilityName { get; set; }
        [Display(Name = "Released In Period By EPRD")]
        public int EPRD { get; set; }
        [Display(Name = "Screened By TCMP")]
        public int Screened { get; set; }
        public int ScreenedPercent { get; set; }
        public int LateReferral { get; set; }
        public int IneligibleLIFER { get; set; }
        public int UnavailableInaccessible { get; set; }
        [Display(Name = "Unavailable Deceased")]
        public int UnavailablDeceased { get; set; }
        public int IneligibleConfirmedHOLD { get; set; }
        public int RefusedAllServices { get; set; }
        public int IneligibleCountyBoarder { get; set; }
        [Display(Name = "Refused Hold")]
        public int RefusedHold { get; set; }
        [Display(Name = "CID Refusal")]
        public int CIDRefusal { get; set; }
        [Display(Name = "COVID19 Related")]
        public int COVID19Related { get; set; }
        [Display(Name = "Total")]
        public int Available { get; set; }
        [Display(Name = "Received Any Services")]
        public int Seen { get; set; }
        public int SeenPercent { get; set; }
        [Display(Name = "Accepted TCMP Services")]
        public int Accepted { get; set; }
        [Display(Name = "MediCal Submitted")]
        public int MediCalApps { get; set; }
        [Display(Name = "SSI Submitted")]
        public int SsiApps { get; set; }
        [Display(Name = "VA Submitted")]
        public int VaApps { get; set; }
        [Display(Name = "CID Service Plan Created")]
        public int SignedCid { get; set; }
        public int MediCalNotProvided { get; set; }
        public int SSINotProvided { get; set; }
        public int VANotProvided { get; set; }
        [Display(Name = "Total Submitted")]
        public int TotalAppsSubmitted { get; set; }
        public int DestParole { get; set; }
        public int DestPRCS { get; set; }
        public int DestDischarged { get; set; }
        public int DestACP { get; set; }
        public int DestMDOSVP { get; set; }
        public int DestINSICE { get; set; }
        public int DestOutOfState { get; set; }
    }

    public class InmatesReleaseDetailsReportData
    {
        [Key]
        public int EpisodeID { get; set; }
        [Required]
        public string CDCRNum { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public string FacilityName { get; set; }
        // release date
        public DateTime EPRD { get; set; }
        public string Housing { get; set; }
        public string StatusDesc { get; set; }
        public string BICNum { get; set; }
        public string CINNum { get; set; }
        public string Outcome { get; set; }
        public int TotalApps { get; set; }
        public int MediCalApps { get; set; }
        public int SsiApps { get; set; }
        public int VaApps { get; set; }
        public int SignedCid { get; set; }
        public string Release { get; set; }
        public string Gender { get; set; }
        public string MentallyIll { get; set; }
        public string Elderly { get; set; }
        public string MediApplyDate { get; set; }
        public string SSIApplyDate { get; set; }
        public string VAApplyDate { get; set; }
        public string BenefitWorkerName { get; set; }
        public string FaceToFaceDate { get; set; }
        public string ExitInterviewDate { get; set; }
    }

    public class ProductivityReportRowDetail
    {
        [Key]
        public int RptProdATID { get; set; }
        public int EpisodeID { get; set; }
        public string EPRD { get; set; }
        public string County { get; set; }
        public string ReleaseTo { get; set; }
        public string MediCalFa { get; set; }
        public string SSIFa { get; set; }
        public string VAFa { get; set; }
        public int BenefitWorkerId { get; set; }
        public string BenefitWorkerName { get; set; }
        public string CDCRNum { get; set; }
        public string ScreeningDate { get; set; }
        public DateTime? MediCalDate { get; set; }
        public DateTime? SsiDate { get; set; }
        public DateTime? VaDate { get; set; }
        public int CentralFileReview { get; set; }
        public int CaseManagement { get; set; }
        public int ExitInterview { get; set; }
        public int FaceToFace { get; set; }
        public int MedicalFileReview { get; set; }
        public int StatusCheckOrUpdate { get; set; }
        public int MediCalSubmission { get; set; }
        public int ServicesNotProvided { get; set; }
        public int ServicesNotProvidedRefused { get; set; }
        public int ServicesNotProvidedOther { get; set; }
        public int SsiSubmission { get; set; }
        public int VaSubmission { get; set; }
        public int CaseAssigned { get; set; }
        public int TcmpChrono { get; set; }
        public int OutcomeLetterCount { get; set; }
        public string OutcomeLetter { get; set; }
        public int CidCreated { get; set; }
        public int CidDeliveredCount { get; set; }
        public string CidDelivered { get; set; }
        public string TelInterview { get; set; }
        public string ExtInterview { get; set; }
        public string MediCalCode { get; set; }
        public string SSICode { get; set; }
        public string VACode { get; set; }
        public int MediCalBnp { get; set; }
        public int SSIBnp { get; set; }
        public int VABnp { get; set; }
        public bool CIDDiscrepancy { get; set; }
        public bool MediCalDiscrepancy { get; set; }
        public bool SsiDiscrepancy { get; set; }
        public bool VaDiscrepancy { get; set; }
        public string AppDate { get; set; }
    }

    public class BWProductivityReportData
    {
        //Name MC#    SSI#   VA#   SNP/Refusal#
        [Key]
        public int BenefitWorkerId { get; set; }
        [Display(Name = "Benefit Worker")]
        public string BenefitWorkerName { get; set; }
        public int EpisodeID { get; set; }
        public string ClientName { get; set; }
        public string CDCRNum { get; set; }
        public int MCTotal { get; set; }
        public int SSITotal { get; set; }
        public int VATotal { get; set; }
        public int SNPRTotal { get; set; }
        public int MediCalBnp { get; set; }
        public int SSIBnp { get; set; }
        public int VABnp { get; set; }
        public int CIDNeedsAssessment { get; set; }
    }

    public class InmatesReportData
    {
        public List<InmatesReleaseReportData> InmatesDataList { get; set; }
        public List<InmatesReleaseDetailsReportData> InmatesDetailsDataList { get; set; }

        public InmatesReportData() { }
    }
    public class FacilityOutlookReportData
    {
        [Key]
        public string FacilityName { get; set; }
        [Display(Name = "Total EPRD 0-30 days")]
        public int Total0T30EPRD { get; set; }
        [Display(Name = "Total EPRD 31-60 days")]
        public int Total31T60EPRD { get; set; }
        [Display(Name = "Total EPRD 61-90 days")]
        public int Total61T90EPRD { get; set; }
        [Display(Name = "Total EPRD 91-120 days")]
        public int Total91T120EPRD { get; set; }
        [Display(Name = "Total EPRD 121-150 days")]
        public int Total121T150EPRD { get; set; }
        [Display(Name = "Total EPRD 151-180 days")]
        public int Total151T180EPRD { get; set; }
        [Display(Name = "Total EPRD 140 days")]
        public int Total140 { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 0-30 days)")]
        public int UnknownDisp0T30EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 0-30 days) / Total 30")]
        public decimal UnknownDisp0T30EPRDPct { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 31-60 days)")]
        public int UnknownDisp31T60EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 31-60 days) / Total 60")]
        public decimal UnknownDisp31T60EPRDPct { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 61-90 days)")]
        public int UnknownDisp61T90EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 61-90 days) / Total 90")]
        public decimal UnknownDisp61T90EPRDPct { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 61-90 days)")]
        public int UnknownDisp91T120EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 91-120 days) / Total 120")]
        public decimal UnknownDisp91T120EPRDPct { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 121-150 days)")]
        public int UnknownDisp121T150EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 121-150 days) / Total 150")]
        public decimal UnknownDisp121T150EPRDPct { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 151-180 days)")]
        public int UnknownDisp151T180EPRD { get; set; }
        [Display(Name = "Unknown Disposition (EPRD 151-180 days) / Total 180")]
        public decimal UnknownDisp151T180EPRDPct { get; set; }
        [Display(Name = "Total EPRD 140 days")]
        public int TotalEPRDnext140days { get; set; }
        [Display(Name = "Total EPRD 140 days pct")]
        public decimal TotalEPRDnext140daysPct { get; set; }
    }
}
