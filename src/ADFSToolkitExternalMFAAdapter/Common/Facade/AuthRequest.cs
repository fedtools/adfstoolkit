
using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace ADFSTK.ExternalMFA.Common.Facade
{
    public class AuthRequest
    {
        public string Token { get; set; }
        public string Upn { get; set; }
        public string OriginIdp { get; set; }
        public string TargetIdp { get; set; }
        public string AuthContextClassRef { get; set; }
        public string IdentityClaimName { get; set; }
        public string IdentityClaimValue { get; set; }
        public DateTime AuthInstant { get; private set; }
        //public string Token { get; set; }
        //public string Upn { get; set; }
        //public DateTime TimeStamp { get; set; }
        //public string OriginIdp { get; set; }
        //public string IdentityClaimName { get; set; }
        //[JsonIgnore(Condition = JsonIgnoreCondition.Always)]
        //public string IdentityClaimValue { get; set; }

    }
}
