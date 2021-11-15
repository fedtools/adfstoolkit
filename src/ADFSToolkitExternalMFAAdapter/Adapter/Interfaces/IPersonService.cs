using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Interfaces
{
    public interface IPersonService
    {
        string GetUniqueIdentifier(string uid);
        bool UniqueIdentifierValid(string localId, string externalId);
    }
}
