using ADFSTK.ExternalMFA.AdapterTest.Helpers;
using Microsoft.IdentityServer.Web.Authentication.External;
using System.Collections.Generic;
using System.IO;
using System.Security.Claims;
using System.Text;
using Xunit;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class AdapterTests
    {
        [Theory]
        [JsonFileData("Config\\ExternalMFASettings.json")]
        public void BeginAuthenticationTest(string json)
        {
           IAuthenticationContext authContext = new AuthenticationContext()
            {
                ActivityId = "minAktivitet",
                ContextId = "minContext",
                Lcid = 1053,
               Data =  new Dictionary<string, object>()
           };

            IAuthenticationMethodConfigData configData = new ConfigData()
            {
                Data = GenerateStreamFromString(json)
            };

            //IProofData proofData = null;//not used only in tryEndAuthentication
            var adapter = new ExternalRefedsMFAAdapter();
            adapter.OnAuthenticationPipelineLoad(configData);
            var c = new Claim("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn", "toylon98@ad.umu.se");
            adapter.BeginAuthentication(c, null, authContext);
        }

        private  MemoryStream GenerateStreamFromString(string value)
        {
            return new MemoryStream(Encoding.UTF8.GetBytes(value ?? ""));
        }
    }
}
