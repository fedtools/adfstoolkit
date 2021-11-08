using Microsoft.IdentityServer.Web.Authentication.External;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class AuthenticationContext : IAuthenticationContext
    {
        public AuthenticationContext()
        {
            //ActivityId = activityId;
        }
        public string ActivityId { get; set; }

        public string ContextId { get; set; }

        public int Lcid  { get; set; }

        public Dictionary<string, object> Data { get; set; }
    }
}
