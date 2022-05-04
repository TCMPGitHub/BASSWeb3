using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities.EditOffender
{
    public enum CASE_NOTE_TYPE_REASON
    {
        //5 --Medical
        MCAppSubmission = 1,
        IntercountyTransfer,
        NOMCRefusedHasAccess,
        NOMCRefusedAboveThreshold,
        NOMCRefusedOther,
        NOMCRefusedIneligibleOutofState,
        //6 --SNP
        RefusedOther,
        UnavailableDeceased,
        UnavailableInaccessible,
        IneligibleLIFER,
        IneligibleConfirmedHOLD,
        LateReferral,
        //8 -- SSI
        AppSubmission3368Pro,
        AppSubmissionReInstatement,
        AppSubmissionAged,
        PhoneInterview,
        DDSRequestSubmitted,
        OutcomeCheck,
        NOSSISSNUnknown,
        NOSSINotLegalResident,
        NOSSIAppeal,
        NOSSIFO,
        NOSSIRefused,
        NOSSICodeNotSupported,
        NOSSICannotConsentOrSign,
        NOSSITemporaryDisability,
        NOSSIlateClassificationChanged,
        //10 -- VA
        VAAppSubmission,
        DD214Requested,
        NOVARefusedHasAccessToVA,
        NOVARefusedMeetWithVARep,
        NOVADeniesVAStatus,
        NOVARefusedOther,
        //19-status Update
        SSI,
        Medical,
        VA,
        //snp
        IneligibleCountyBoarder,
        //SSI
        NOSSIIncomeAboveThreshold,
        //snp
        UnavailableDeployed,
        //SSI
        DDSSignatureRequest,
        DDSSignatureObtained,
        //Med-cal
        MCAppSubmissionReInstatement,
        //snp
        RefusedHold,
        //CID
        NOCIDRefusedHasAccess,
        NOCIDTransferredOutsideCDCR,
        //SNP
        CIDRefusal,
        COVID19Related,
        MDOORSVP,
        //Case Management
        AttendedPRVCMeeting,
        AttendedISUDTMeeting,
        AllNotes
    }
    public class CaseNoteTypeReason
    {
        public CaseNoteTypeReason() { }
        public CaseNoteTypeReason(int casenotetypeid)
        {
            this.CaseNoteTypeID = casenotetypeid;
        }
        [Key]
        [DatabaseGeneratedAttribute(DatabaseGeneratedOption.Identity)]
        public int CaseNoteTypeReasonID { get; set; }
        public int CaseNoteTypeID { get; set; }
        [StringLength(75), Column(TypeName = "nvarchar")]
        public string Name { get; set; }
        public int Position { get; set; }
        public bool? Disabled { get; set; }
        public DateTime DateAction { get; set; }
        [ForeignKey("CaseNoteTypeID")]
        public virtual CaseNoteType CaseNoteType { get; set; }
        [NotMapped]
        public string CaseSelectedReason
        {
            get
            {
                return this.Name;
            }
        }
    }
}
