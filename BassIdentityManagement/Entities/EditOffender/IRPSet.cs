using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class IRPSet
    {
        public int IRPID { get; set; }
        public int NeedID { get; set; }
        public int? NeedStatus { get; set; }
        public bool? NeedStatus1 { get; set; }
        public bool? NeedStatus2 { get; set; }
        public bool? NeedStatus3 { get; set; }
        public bool? NeedStatus4 { get; set; }
        public string Need { get; set; }
        public string DescriptionCurrentNeed { get; set; }
        public string ShortTermGoal { get; set; }
        public string LongTermGoal { get; set; }
        public bool? LongTermStatusMet { get; set; }
        public bool? LongTermStatusNoMet { get; set; }
        public DateTime? LongTermStatusDate { get; set; }
        public string PlanedIntervention { get; set; }
        public string Note { get; set; }
        public string IDTTDecision { get; set; }
        public bool IsLastIRPSet { get; set; }
        public int ActionStatus { get; set; }
        public string ActionName { get; set; }
        public DateTime DateAction { get; set; }
    }

    public class IRPDates
    {
        public int IRPID { get; set; }
        public string IRPDate { get; set; }
    }
}
