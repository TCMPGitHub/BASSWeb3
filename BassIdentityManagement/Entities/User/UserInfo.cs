using Microsoft.AspNet.Identity;
using System;
using System.ComponentModel.DataAnnotations;

namespace BassIdentityManagement.Entities
{
    public class UserInfo : IUser<int>
    {
        [Key]
        public int UserID { get; set; }
        public string UserName { get; set; }
        public string PasswordHash { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public bool IsActive { get; set; }
        public bool IsBenefitWorker { get; set; }
        public int LoginFailures { get; set; }
        public bool CanEditAllCases { get; set; }
        public bool CanEditAllNotes { get; set; }
        public bool CanAccessReports { get; set; }
        public bool CaseNoteHidden { get; set; }
        public string Email { get; set; }
        public bool EmailComfirmed { get; set; }
        public bool IsADUser { get; set; }
        public DateTime? LastPasswordChangedDate { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public bool ViewBenefitOnly { get; set; }
        public bool DocumentHidden { get; set; }
        public int? SupervisorID { get; set; }
        
        int IUser<int>.Id
        {
            get
            {
                return this.UserID;
            }
        }

        string IUser<int>.UserName
        {
            get
            {
                return this.UserName;
            }

            set
            {
                this.UserName = value;
            }
        }

        public string UserLFI()
        {
            return this.LastName + ", " + this.FirstName.Substring(0, 1) + ".";
        }

        public string UserLFM()
        {
            return this.LastName + ", " + this.FirstName + " " + (string.IsNullOrEmpty(this.MiddleName) ? "" : this.MiddleName);
        }

        public string UserFML()
        {
            return this.FirstName + " " + (string.IsNullOrEmpty(this.MiddleName) ? "" : this.MiddleName) + " " + this.LastName;
        }
    }
}
    