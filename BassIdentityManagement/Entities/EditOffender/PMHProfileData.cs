using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class PMHProfileData
    {
        public string CDCNUMBER { get; set; }
        public string PAROLEENAME { get; set; }
        public string PAROLEEAGENT { get; set; }
        //public DateTime? DATE { get; set; }
        public bool NORTHERN { get; set; }    //region
        public bool SOUTHERN { get; set; }    //region
        public bool MALE { get; set; }
        public bool FEMALE { get; set; }
        public string PAROLEUNIT { get; set; }
        public string StaffAssigned { get; set; }
        public string StreetAddress { get; set; }
        public string City { get; set; }
        public string ZIPCode { get; set; }
        public string State { get; set; }
        public DateTime? DOB { get; set; }
        public int AddressID { get; set; }
        public int FacilityID { get; set; }
        public string SOCIALSECURITYNUMBER { get; set; }

        //SignificantOther
        public bool Married { get; set; }
        public bool Separated { get; set; }
        public bool Divorced { get; set; }
        public bool Widowed { get; set; }
        public bool Cohabitating { get; set; }
        public bool Single { get; set; }
        public bool DomesticPartner { get; set; }

        public string ParoleePhoneResidence { get; set; }
        public string ParoleePhoneWork { get; set; }
        public string EmergencyContactName { get; set; }
        public string EmergencyContactPhoneResidence { get; set; }
        public string EmergencyContactPhoneWork { get; set; }
        public int EmergencyContactID { get; set; }
        public int ParoleeWorkID { get; set; }

        //ETHNIC Background
        public bool White { get; set; }
        public bool AmericanIndian { get; set; }
        public bool Asian { get; set; }
        public bool AfricanAmerican { get; set; }
        public bool Hispanic { get; set; }
        public bool Other { get; set; }

        //Current Mental Health Designation
        public bool CCCMS { get; set; }
        public bool EOP { get; set; }
        public bool MHNONE { get; set; }

        //DDP Status
        public bool NCF { get; set; }
        public bool NDD { get; set; }
        public bool DD0 { get; set; }
        public bool DD1 { get; set; }
        public bool DD2 { get; set; }
        public bool DD3 { get; set; }
        public bool DDPNone { get; set; }

        public DateTime? RECENTRELEASEDATE { get; set; }
        public string CSRASCORE { get; set; }
        public DateTime? DISCHARGEREVIEWDATE { get; set; }

        //type release
        public bool Prison { get; set; }
        public bool CountyJail { get; set; }
        public bool CourtWalkover { get; set; }
        public bool ReleaseTypeNone { get; set; }

        //DDP status
        public bool Mobility { get; set; }
        public bool Hearing { get; set; }
        public bool Vision { get; set; }
        public bool DPPSTATUSNone { get; set; }

        public string COMPASCRIMINOGENICNEEDS { get; set; }
        public DateTime? CONTROLLINGDISCHARGEDATE { get; set; }
        public string CCIINSTITUTIONINFORMATION { get; set; }
        public string ADDITIONALINFORMATION { get; set; }
        public DateTime DATE { get; set; }
       
        //public List<tlkpFacility> FacilityList { get; set; 
    }
        public class Facilities
        {
            public int FacilityID { get; set;}
            public string Abbr { get; set; }
            public string Name { get; set; }
       }
    }
