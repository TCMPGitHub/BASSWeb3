using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BassWebV3.ViewModels
{
    public class InmateData
    {
        public int EpisodeID { get; set; }
        public bool ShowCaseNoteList { get; set; }
        public bool EditingEnabled { get; set; }
        public OffenderData Offender { get; set; }
        public Applications Appliations { get; set; }
        public CaseNoteFiles CaseNF { get; set; }
    }
}