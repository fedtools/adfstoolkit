using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Settings
{
    [DataContract]
    public class LdapSettings
    {
        [DataMember]
        public string UserName { get; set; }
        [DataMember]
        public string Password { get; set; }
        [DataMember]
        public string SearchRoot { get; set; }
        [DataMember]
        public string Filter { get; set; }
        [DataMember]
        public string AttributeToRetrieve { get; set; }

    }
}
