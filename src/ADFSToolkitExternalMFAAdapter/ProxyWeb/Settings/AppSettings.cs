using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace EduIDExternalWeb.Settings
{
    public class AppSettings
    {
        public string BaseUrl { get; set; }
        public string SamlEndpoint { get; set; }
        public string Subsite { get; set; }
        public string Target  { get; set; }
        public string GetRedirectUrl(string upn)
        {
            var baseUrl = string.Join("/",BaseUrl,Subsite);
            return BaseUrl +this.SamlEndpoint+ "?entityID={0}&authnContextClassRef={1}&forceAuthn=true&target=" + baseUrl+this.Target+"&username="+upn;
        }

    }
}
