using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class BassLists
    {
    }
    public class EpisodeAssignedList
    {
        public int EpisodeID { get; set; }
        public string AssignedInmate { get; set; }
    }
    public class Episodes
    {
        public int  EpisodeID { get; set; }
        public string ReferralDate { get; set; }
    }
    public class LoadedEpisode
    {
        public int EpisodeID { get; set; }
        public string CDCRNum { get; set; }
    }
    public class County
    {
        [Key]
        public int CountyID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
    }

    public class Facility
    {
        [Key]
        public int FacilityID { get; set; }
        [StringLength(50)]
        public string NameWithCode { get; set; }
        public string Abbr { get; set; }
    }
    public class FacilityList
    {
        [Key]
        public int FacilityID { get; set; }
        public string FacilityName { get; set; }
    }
    public class Gender
    {
        [Key]
        public int GenderID { get; set; }
        [StringLength(1)]
        public string Code { get; set; }
        [StringLength(15)]
        public string Name { get; set; }
    }

    public class EpisodeAcpDshType
    {
        [Key]
        public int EpisodeAcpDshTypeID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
    }
    public class EpisodeMdoSvpType
    {
        [Key]
        public int EpisodeMdoSvpTypeID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
    }
    public class EpisodeMedReleaseType
    {
        [Key]
        public int EpisodeMedReleaseTypeID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
    }
    public class LookUpTable
    {
        [Key]
        public int lkValue { get; set; }
        [StringLength(100)]
        public string lkdescr_short { get; set; }
    }
    public class CaseNoteTypeReasonList
    {
        [Key]
        public int CaseNoteTypeReasonID { get; set; }
        public int CaseNoteTypeID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
        public int Position { get; set; }
    }
    public class CaseNoteTypeList
    {
        [Key]
        public int CaseNoteTypeID { get; set; }
        [StringLength(25)]
        public string Name { get; set; }
    }

    public class AssignmentUserList
    {
        public int UserID { get; set; }
        public string BenefitWorkerName { get; set; }
    }
    public class ReleasePeriod
    {
        public int PeriodID { get; set; }
        public string Period { get; set; }
        public string Abbr { get; set; }
    }

    public class SupervisorList
    {
        public int SupervisorID { get; set; }
        public string SupervisorName { get; set; }
    }

    public class UserStatus
    {
        public int UserID { get; set; }
        public int SupervisorID { get; set; }
        public int FacilityID { get; set; }
        public string UserName { get; set; }
        public string LocationNote { get; set; }
    }
}

