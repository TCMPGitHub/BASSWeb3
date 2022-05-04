using System.ComponentModel.DataAnnotations;
using System;
using Kendo.Mvc.UI;

namespace BassWebV3.ViewModels
{
    public class AppModel
    {
        public DateTime AppDate { get; set; }
        public decimal Current { get; set; }  //current
        public decimal Target { get; set; }  //Target
    }
    public class TeamManagement
    {
        [Required]
        public int UserID { get; set; }
        [Required]
        public string FirstName { get; set; }
        public string UserName { get; set; }
        [Required]
        public string LastName { get; set; }
        public string Title { get; set; }
        [Required]
        public string Notes { get; set; }
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }

    }

    public class CasesWorded
    {
        public int? UserID { get; set; }
        public int? UserCasesWorkdTotals { get; set; }
        public DateTime Date { get; set; }
    }

    public class UserAndTeamCasesworked
    {
        public DateTime Date { get; set; }
        public int? UserTotalCasesWorked { get; set; }
        public int? TeamTotalCasesWorked { get; set; }
        
    }

    public class CasesWorkedLocation : ISchedulerEvent
    {
        public int PageLoadID { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }

        private DateTime start;
        public DateTime Start
        {
            get
            {
                return start;
            }
            set
            {
                start = value.ToUniversalTime();
            }
        }

        public string StartTimezone { get; set; }

        private DateTime end;
        public DateTime End
        {
            get
            {
                return end;
            }
            set
            {
                end = value.ToUniversalTime();
            }
        }

        public string EndTimezone { get; set; }
        public string RecurrenceRule { get; set; }
        public int? RecurrenceID { get; set; }
        public string RecurrenceException { get; set; }
        public bool IsAllDay { get; set; }
        public int? UserID { get; set; }
    }
}