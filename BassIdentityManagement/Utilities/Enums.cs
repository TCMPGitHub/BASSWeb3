using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Utilities
{
    public enum EnumUserStatus
    {
        Pending = 0,
        Active,
        LockedOut,
        Closed,
        Banned
    }
}