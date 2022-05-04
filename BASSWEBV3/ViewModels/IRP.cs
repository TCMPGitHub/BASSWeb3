using BassIdentityManagement.Entities;
using System.Collections.Generic;
namespace BassWebV3.ViewModels
{
    public class IRP
    {
        public int PATSEpisodeID { get; set; }
        public string CDCRNum { get; set; }
        public string ActionUserName { get; set; }
        public List<IRPSet> IRPSetList { get; set; }
        public bool CanEdit { get; set; }
        public IRP() { }
    }
}