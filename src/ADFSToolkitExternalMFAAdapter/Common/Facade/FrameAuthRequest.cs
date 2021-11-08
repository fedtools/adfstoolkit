
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Facade
{
    public class FrameAuthRequest
    {
        public FrameAuthRequest()
        {
            AuthInstant = DateTime.UtcNow;
        }
        public string Token { get; set; }
        public string OriginIdp { get; set; }
        public string TargetIdp { get; set; }
        public string AuthContextClassRef { get; set; }
        public string IdentityClaimName { get; set; }
        public string IdentityClaimValue { get; set; }
        public DateTime AuthInstant { get; private set; }

    }
}
