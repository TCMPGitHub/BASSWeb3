using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BassWebV3.ViewModels
{


    public class Applications
    {
        public bool CanEditApplication { get; set; }
        public ApplicationUser User { get; set; }
        public ApplicationFlags AppFlags { get; set; }
        public Applications() { }
    }
}