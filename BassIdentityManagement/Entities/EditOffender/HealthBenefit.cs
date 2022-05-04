using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class HealthBenefit
    {
        public int EpisodeId { get; set; }
        public int ID { get; set; }
        public string BenefitTypeDesc { get; set; }
        public string AgreeType { get; set; }
        [Required(ErrorMessage = "Converage name is required")]
        public int? BenefitTypeID { get; set; }
        [DataType(DataType.Date)]
        public DateTime? AppliedOrRefusedOnDate { get; set; }
        public DateTime? PhoneInterviewDate { get; set; }
        public DateTime? OutcomeDate { get; set; }
        public int? OutcomeID { get; set; }
        public string Outcome { get; set; }
        public string BICNum { get; set; }      //Note: BICNum = MediCal Number
        public DateTime? IssuedOnDate { get; set; }
        public DateTime? ArchivedOnDate { get; set; }
        public int? ActionStatus { get; set; }
        public int? ActionBy { get; set; }
        public string ActionByName { get; set; }
        public bool AppliedOrRefused { get; set; }  // apply or refuse
        [StringLength(4000, ErrorMessage = "Cannot exceed {2} characters.")]
        public string NoteorComment { get; set; }
        public DateTime? DateAction { get; set; }
        public int Totals { get; set; }
       
    }
    public class BenefitType
    {
        public int BenefitTypeID { get; set;}
        public string Name { get; set; }
    }

    public class OutcomeType
    {
        public int ApplicationOutcomeID { get; set; }
        public string Name { get; set; }
        public int Position { get; set; }
    }
}
