using ADFSTK.ExternalMFA.Interfaces;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Services
{
    public class PersonServiceMock : IPersonService
    {
        public string GetUniqueIdentifier(string uid)
        {
            return string.Empty;
        }

        public bool UniqueIdentifierValid(string localId, string externalId)
        {
            EventLog.WriteEntry("AD FS", "Warning, a mocked personservice is used!", EventLogEntryType.Warning, 335);
            return true;
        }
    }
}
