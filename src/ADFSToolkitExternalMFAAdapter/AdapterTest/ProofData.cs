using Microsoft.IdentityServer.Web.Authentication.External;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class ProofData : IProofData
    {
        public ProofData()
        {

        }
        public Dictionary<string, object> Properties { get; set; }
    }
}
