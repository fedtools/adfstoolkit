using Microsoft.IdentityServer.Web.Authentication.External;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class ConfigData : IAuthenticationMethodConfigData
    {
        public Stream Data { get; set; }
    }
}
