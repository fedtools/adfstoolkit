using ADFSTK.ExternalMFA.Common.Settings;
using ADFSTK.ExternalMFA.Interfaces;
using ADFSTK.ExternalMFA.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LdapTest
{
    
    public class LdapTest
    {
        private IPersonService _personService;

        public LdapTest(LdapSettings settings)
        {
            _personService = new PersonServiceLdap(settings);
        }
        public string GetCivicNumber(string uid)
        {
            return _personService.GetUniqueIdentifier(uid);
        }
    }
}
