using System;
using System.Collections.Generic;
using System.Linq;
namespace BassIdentityManagement.Entities
{
    public class ActiveBASSUser
    {
        public int StaffId { get; set; }
        public string StaffName { get; set; }
        public string StaffType { get; set; }
        public int StaffTypeId { get; set; }
        public int LocationId { get; set; }
        public int ComplexId { get; set; }
        public bool IsCurrentUser { get; set; }

    }

    public class ActiveUserList
    {
        public int UserID { get; set; }
        public string UserLFM { get; set; }
    }
}
