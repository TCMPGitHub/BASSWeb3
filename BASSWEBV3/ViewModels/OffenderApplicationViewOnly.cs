using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BassWebV3.ViewModels
{
    public class OffenderApplicationViewOnly
    {
        public int EpisodeID { get; set; }
        public int ReleaseCountyID { get; set; }
        public string SearchString { get; set; }
    }
}