using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class CaseNoteData
    {
        public int CaseNoteID { get; set; }
        public int CaseNoteTraceID { get; set; }
        [Required(ErrorMessage = "Must select a case note type")]
        public int CaseNoteTypeID { get; set; }
        public string CaseNoteType { get; set; }
        public int? CaseNoteTypeReasonID { get; set; }
        public int UserID { get; set; }
        public string CaseNoteTypeReason { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime CreateDate { get; set; }
        [Required(ErrorMessage = "Case note cannot be empty.")]
        public string Text { get; set; }
        public string CreatedBy { get; set; }
        public int ActionStatus { get; set; }
        public bool NoteCanEdit { get; set; }
    }
    //public class CaseNoteData
    //{
    //    public int Id { get; set; }
    //    public int CaseNoteId { get; set; }
    //    [Range(1, int.MaxValue, ErrorMessage = "Note type is required")]
    //    public int CaseNoteTypeId { get; set; }
    //    public bool UpdateExpired { get; set; }  //24 hours
    //    public string CaseNoteType { get; set; }
    //    [Range(1, int.MaxValue, ErrorMessage = "Contact method is required")]
    //    public int CaseContactMethodID { get; set; }
    //    public string CaseContactMethod { get; set; }
    //    [Required(ErrorMessage = "Note is required")]
    //    public string Note { get; set; }
    //    public DateTime DateAction { get; set; }
    //    public string ActionByName { get; set; }
    //    public string ActionModel { get; set; }
    //    //public bool HasHistory { get; set; }
    //}
    public class CaseNoteHistory
    {
        public int Id { get; set; }
        public int CaseNoteId { get; set; }
        public DateTime DateAction { get; set; }
        public string HisNote { get; set; }
        public string CaseContactMethod { get; set; }
        public string CaseNoteType { get; set; }
        public string ActionByName { get; set; }
        public string ActionStatus { get; set; }
        public string ActionModel { get; set; }

    }
    public class CaseNoteInfo
    {
        public string CDCRNum { get; set; }
        public string ClientName { get; set; }
        public string NoteDate { get; set; }
        public string NoteType { get; set; }
        public string ContactMethod { get; set; }
        public string EnteredBy { get; set; }
        public string Note { get; set; }
        public string CaseWorkerType { get; set; }
    }
    public class CaseContactMethod
    {
        public int CaseContactMethodID { get; set; }
        public string ContactMethod { get; set; }
    }
}
