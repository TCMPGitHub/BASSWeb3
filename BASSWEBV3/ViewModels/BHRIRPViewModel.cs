using System.Collections.Generic;
using BassIdentityManagement.Entities;

namespace BassWebV3.ViewModels
{
    public class BHRIRPViewModel
    {
        public BHRIRPData IRP { get; set; }
        public List<IdentifiedBarriersToIntervention> IBTIList { get; set; }
        public List<BarrierFrequency> BarrFreqList { get; set; }
        public bool CanEdit { get; set; }
        public string ActionUserName { get; set; }
        public int PATSEpisodeID { get; set; }
        //public MvcHtmlString NoEditAllowed { get; set; }
        public BHRIRPViewModel() { }
    }
}