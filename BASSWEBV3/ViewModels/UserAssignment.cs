using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BassWebV3.ViewModels
{
    public class UserAssignment
    {
        public int UserId { get; set; }
        public bool IsBenifitWorker { get; set; }
        public UserAssignment() { }
    }
    public class UserWorkLocation
    {
        public int UserId { get; set; }
        public bool IsBenifitWorker { get; set; }
        public UserWorkLocation() { }
    }
}