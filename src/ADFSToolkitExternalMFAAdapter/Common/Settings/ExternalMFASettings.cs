using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Emit;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Settings
{
    [DataContract(Name ="EduIDMFASettings")]
    public class ExternalMFASettings
    {
        [DataMember(Name = "OriginIdp")]
        public string OriginIdp { get; set; }
        [DataMember(Name = "TargetIdp")]
        public string TargetIdp { get; set; }
        [DataMember(Name = "AuthContextClassRef")]
        public string AuthContextClassRef { get; set; }
        [DataMember(Name = "IdentityClaimName")]
        public String   IdentityClaimName{ get; set; }
        [DataMember(Name = "ProxySp")]
        public string ProxySp { get; set; }
        [DataMember(Name = "CryptoKey")]
        public string CryptoKey { get; set; }
        [DataMember(Name = "PersonServiceImpl")]
        public string PersonServiceImpl { get; set; }
        [DataMember(Name ="LdapSettings")]
        public LdapSettings LdapConfig { get; set; }
        [DataMember(Name ="SqlSettings")]
        public SqlSettings SqlConfig { get; set; }
    }
}
