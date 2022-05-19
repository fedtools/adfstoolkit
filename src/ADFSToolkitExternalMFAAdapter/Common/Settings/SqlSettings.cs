using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Settings
{
    [DataContract]
    public class SqlSettings
    {
        [DataMember]
        public string GuestConnStr { get; set; }
        [DataMember]
        public string UserConnStr { get; set; }
        [DataMember]
        public string GuestCmd { get; set; }
        [DataMember]
        public string UserCmd { get; set; }

    }
}
