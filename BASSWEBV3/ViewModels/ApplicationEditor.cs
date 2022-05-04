using BassIdentityManagement.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BassWebV3.ViewModels
{
    public class ApplicationEditor
    {
        public ApplicationData App { get; set; }
        public string ErrorMessage { get; set; }
        public string ApplicationTypeName { get; set; }
        public bool NeedPI { get; set; }
        public bool Needbic { get; set; }
        public List<Facility> Facilities { get; set; }
        public List<OutcomeType> Outcomes { get; set; }
        public ApplicationEditor() { }
    }
}