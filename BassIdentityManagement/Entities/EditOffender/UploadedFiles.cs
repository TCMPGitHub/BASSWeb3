using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BassIdentityManagement.Entities
{
    public class UploadedFiles
    {
        public int ID { get; set; }
        public int EpisodeId { get; set; }
        public string FileName { get; set; }
        public DateTime UploadDate { get; set; }
        public byte[] FileData { get; set; }
        public int FileSize { get; set; }
        public string UploadBy { get; set; }

    }
}
