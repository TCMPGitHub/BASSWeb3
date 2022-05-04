using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace BassIdentityManagement.Entities
{
    public enum CASE_NOTE_TYPE
    {
        CentralFileReview = 0,
        CaseManagement = 1,
        ExitInterview,
        FaceToFace,
        MedicalFileReview,
        MediCal,
        ServicesNotProvided,
        PharmacyFileReview,
        SSI,
        TelephoneInterview,
        VA,
        CaseAssigned,
        TCMPChrono,
        OutcomeLetter,
        Other,
        CollateralContact,
        CIDSPCreated,
        CIDSPDelivered,
        ScanUploadDocs,
        StatusUpdate,
        CIDSPNotDelivered,
        CIDRefusal,
        CIDUnavailableInaccessible
    }
    public enum LegacyActionTypeID : short
    {
        Other = 0,
        CentralFileReview = 1,
        CollateralContact = 2,
        FaceToFace = 3,
        MedicalFileReview = 4,
        PharmacyFileReview = 5,
        TelephoneInterview = 6,
        SsiSubmission = 7,
        MediCalSubmission = 8,
        VaSubmission = 9,
        ExitInterview = 10,
    }
    public class CaseNoteType
    {
        public int CaseNoteTypeID { get; set; }

        [StringLength(50)]
        public string Name { get; set; }
    }
}
