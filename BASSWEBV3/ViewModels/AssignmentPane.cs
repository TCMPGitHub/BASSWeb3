using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.ComponentModel.DataAnnotations;
using BassIdentityManagement.Entities;

namespace BassWebV3.ViewModels.CaseAssignment
{
    public sealed class CasePriority
    {
        public static readonly CasePriority LongTermMedCare = new CasePriority("Long Term Medical Care", "LongTerm", 16384);
        public static readonly CasePriority Hospice = new CasePriority("Hospice", "Hospice", 8192);
        public static readonly CasePriority AssistedLiving = new CasePriority("Assisted Living", "AsstLiving", 4096);
        public static readonly CasePriority HIVPos = new CasePriority("HIV Positive", "CID", 2048);
        public static readonly CasePriority ChronicIllness = new CasePriority("Chronic Illness", "Chronic", 1024);
        public static readonly CasePriority EOP = new CasePriority("EOP", "EOP", 512);
        public static readonly CasePriority PhysDisabled = new CasePriority("Physically Disabled", "PD", 256);
        public static readonly CasePriority DevDisabled = new CasePriority("Developmentally Disabled", "DP", 128);
        public static readonly CasePriority USVet = new CasePriority("US Veteran", "Vet", 64);
        public static readonly CasePriority CCCMS = new CasePriority("CCCMS", "CCCMS", 16);//2015-10-26 EJ changed CCCMS from 2 to 3
        public static readonly CasePriority Elderly = new CasePriority("Elderly", "65+", 8);//2015-10-26 EJ changed from 1 to 2
        public static readonly CasePriority DSH = new CasePriority("DSH", "DSH", 4);//2015-10-26 EJ added DSH with rank = 1 
                                                                                    //public static readonly CasePriority SSI = new CasePriority("SSI", "SSI", 32768);

        public static readonly CasePriority GP = new CasePriority("General Population", "GP", 0);

        private CasePriority(string name, string abrv, int rank)
        {
            Name = name;
            Abrv = abrv;
            Rank = rank;
        }

        public string Name { get; private set; }
        public string Abrv { get; private set; }
        public int Rank { get; set; }

      

        public static CasePriority Calculate(bool longTermMedCare = false, bool hospice = false, bool assistedLiving = false, bool hivPos = false, bool chronicIllness = false, bool eop = false, bool physDisabled = false, bool devDisabled = false, bool cccms = false, bool elderly = false, bool dsh = false, bool usVet = false, bool ssi = false)
        {
            //string name = null;
            CasePriority highestPriority;
            int rankSum = 0;

            if (longTermMedCare) highestPriority = LongTermMedCare;
            else if (hospice) highestPriority = Hospice;
            else if (assistedLiving) highestPriority = AssistedLiving;
            else if (hivPos) highestPriority = HIVPos;
            else if (chronicIllness) highestPriority = ChronicIllness;
            else if (eop) highestPriority = EOP;
            else if (physDisabled) highestPriority = PhysDisabled;
            else if (devDisabled) highestPriority = DevDisabled;
            else if (usVet) highestPriority = USVet;
            //else if (vrss) highestPriority = VRSS;
            else if (cccms) highestPriority = CCCMS;
            else if (elderly) highestPriority = Elderly;
            else if (dsh) highestPriority = DSH;
            //else if (ssi) highestPriority = SSI;
            else highestPriority = GP;

            if (longTermMedCare) rankSum += LongTermMedCare.Rank;
            if (hospice) rankSum += Hospice.Rank;
            if (assistedLiving) rankSum += AssistedLiving.Rank;
            if (hivPos) rankSum += HIVPos.Rank;
            if (chronicIllness) rankSum += ChronicIllness.Rank;
            if (eop) rankSum += EOP.Rank;
            if (physDisabled) rankSum += PhysDisabled.Rank;
            if (devDisabled) rankSum += DevDisabled.Rank;
            if (usVet) rankSum += USVet.Rank;
            if (cccms) rankSum += CCCMS.Rank;
            if (elderly) rankSum += Elderly.Rank;
            if (dsh) rankSum += DSH.Rank;
            //if (ssi) rankSum += SSI.Rank;
            //if (vrss) rankSum += VRSS.Rank;
            // Note that GP has rank 0, so no need to add anything for that case

            return new CasePriority(highestPriority.Name, highestPriority.Abrv, rankSum);
        }
    }
    public class AssignmentPane
    {
        public class CaseAssignmentUptodate
        {
            public CasePriority CasePriority { get; set; }
            public string CDCRNum { get; set; }
            public string OffenderName { get; set; }
            public string Housing { get; set; }
            public DateTime ReleaseDate { get; set; }
            public bool HIV { get; set; }
            public bool ChronicIll { get; set; }
            public string MHSDSDesc { get; set; }
            public string Disability { get; set; }
            public bool Elderly { get; set; }
            public bool USVet { get; set; }
            public string MedPlacementDesc { get; set; }
            public bool Lifer { get; set; }
            public string DSH { get; set; }
            public string SSI { get; set; }
        }
        public class EpisodeCheckbox
        {
            [Required]
            public bool IsChecked { get; set; }
            [Required]
            public int EpisodeID { get; set; }

            //public Episode Episode { get; set; }
            public CasePriority CasePriority { get; private set; }
            public string CDCRNum { get; private set; }
            public string OffenderName { get; private set; }
            public string ReleaseDate { get; private set; }
            public string ReleaseDateSort { get; private set; }
            public string HIVDesc { get; private set; }
            public string ChronicIllDesc { get; private set; }
            public string MHSDSDesc { get; private set; }
            public string DisabilityDesc { get; private set; }
            public string ElderlyDesc { get; private set; }
            public string USVetDesc { get; private set; }
            public string MedPlacementDesc { get; private set; }
            public string LiferDesc { get; private set; }
            public string Housing { get; private set; }
            public string DSH { get; private set; }
            public string SSI { get; private set; }
            //2015-10-26 EJ added this as a referral qualifier
            public EpisodeCheckbox() { } // Necessary to prevent "Internal Server Error" on form submission

            public class testc
            {
                public bool IsChecked { get; set; }
                public int EpisodeID { get; set; }
                public string DisabilityDesc { get; set; }
                public string MHSDSDesc { get; set; }
                //public bool PhysDisabled) disabilityList.Add("DPP");
                //if (episode.Offender.DevDisabled) disabilityList.Add("DDP");

                //var MhsdsList = new List<string>();
                //if (episode.Offender.EOP) MhsdsList.Add("EOP");
                //if (episode.Offender.CCCMS) MhsdsList.Add("CCCMS");

                public CasePriority asePriorities { get; set; }
                public string CDCRNum { get; set; }
                public string ClientName { get; set;}
                public string Housing { get; set; }
                public DateTime? ReleaseDate { get; set; }
                public bool HIVPos { get; set;}
                public bool ChronicIllness { get; set; }
                public bool Elderly { get; set; }
                public bool USVet { get; set; }
                public bool MedPlacement { get; set; }
                public bool Lifer { get; set; }
                public bool DSH { get; set; }
                public bool SSI { get; set; }
                //OffenderName = episode.Offender.LastFirstMI;
                //ReleaseDate = String.Format("{0:MM/dd/yyyy}", episode.ReleaseDate);
                //ReleaseDateSort = String.Format("{0:yyyy/MM/dd}", episode.ReleaseDate ?? DateTime.MaxValue); // If ReleaseDate is null, use a placeholder "later than everything else" date for sorting
                //HIVDesc = YesNo(episode.Offender.HIVPos);
                //ChronicIllDesc = YesNo(episode.Offender.ChronicIllness);
                //MHSDSDesc = String.Join(", ", MhsdsList);
                //DisabilityDesc = String.Join(", ", disabilityList);
                //ElderlyDesc = YesNo(episode.Offender.Elderly);
                //USVetDesc = YesNo(episode.Offender.USVet);

                //MedPlacementDesc = YesNo(episode.Offender.MedPlacement);
                //LiferDesc = YesNo(episode.Lifer);
                //DSH = YesNo(episode.Offender.DSH);
                //SSI = YesNo(episode.Offender.SSI);
            }
            //public EpisodeCheckbox(Episode episode)
            //{
            //    IsChecked = false;
            //    EpisodeID = episode.EpisodeID;

            //    var disabilityList = new List<string>();
            //    if (episode.Offender.PhysDisabled) disabilityList.Add("DPP");
            //    if (episode.Offender.DevDisabled) disabilityList.Add("DDP");

            //    var MhsdsList = new List<string>();
            //    if (episode.Offender.EOP) MhsdsList.Add("EOP");
            //    if (episode.Offender.CCCMS) MhsdsList.Add("CCCMS");

            //    CasePriority = episode.CasePriority;
            //    CDCRNum = episode.CDCRNum;
            //    OffenderName = episode.Offender.LastFirstMI;
            //    ReleaseDate = String.Format("{0:MM/dd/yyyy}", episode.ReleaseDate);
            //    ReleaseDateSort = String.Format("{0:yyyy/MM/dd}", episode.ReleaseDate ?? DateTime.MaxValue); // If ReleaseDate is null, use a placeholder "later than everything else" date for sorting
            //    HIVDesc = YesNo(episode.Offender.HIVPos);
            //    ChronicIllDesc = YesNo(episode.Offender.ChronicIllness);
            //    MHSDSDesc = String.Join(", ", MhsdsList);
            //    DisabilityDesc = String.Join(", ", disabilityList);
            //    ElderlyDesc = YesNo(episode.Offender.Elderly);
            //    USVetDesc = YesNo(episode.Offender.USVet);
            //    Housing = episode.Housing;
            //    MedPlacementDesc = YesNo(episode.Offender.MedPlacement);
            //    LiferDesc = YesNo(episode.Lifer);
            //    DSH = YesNo(episode.Offender.DSH);
            //    SSI = YesNo(episode.Offender.SSI);
            //}

            private string YesNo(bool isTrue)
            {
                return isTrue ? "Yes" : "No";
            }
        }



        [Required]
        public int SelectedBenefitWorkerID { get; set; }

        public List<EpisodeCheckbox> EpisodeCheckboxes { get; set; }

        public IEnumerable<SelectListItem> AllBenefitWorkers { get; private set; }



        public AssignmentPane()
        {
            EpisodeCheckboxes = new List<EpisodeCheckbox>();
        }

        //public AssignmentPane(IQueryable<User> users)
        //    : this()
        //{
        //    var query = users.Select(u => new { Value = u.UserID, Text = u.LastName + ", " + u.FirstName }).OrderBy(x => x.Text);
        //    AllBenefitWorkers = new SelectList(query.AsEnumerable(), "Value", "Text");
        //}


       // public AssignmentPane(List<Episode> searchResults, IQueryable<ApplicationUser> users)
       //{
       //     EpisodeCheckboxes = new List<EpisodeCheckbox>();

       //     foreach (var episode in searchResults)
       //     {
       //         EpisodeCheckboxes.Add(new EpisodeCheckbox(episode));
       //     }
       // }
    }


}