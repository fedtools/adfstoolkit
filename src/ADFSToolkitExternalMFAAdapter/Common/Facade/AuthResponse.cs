using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Facade
{
    public class AuthResponse
    {
        public string Token { get; set; }
        public string Upn { get; set; }
        public string TargetIdp { get; set; }
        public string Status { get; set; }
        public string IdentityClaimName { get; set; }
        public string IdentityClaimValue { get; set; }
        public List<string> Assurance { get; set; }
        public DateTime TimeStamp { get; set; }
    }
}
