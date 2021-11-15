using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common
{
    public enum AuthStatusCodes
    {
        STARTED,
        APPROVED,
        REJECTED,
        CANCELED,
        EXPIRED,
        RP_CANCELED
    }
    public enum ValidAuthStatusCodes
    {
        APPROVED
    }
    public enum InvalidValidAuthStatusCodes
    {
        REJECTED,
        CANCELED,
        EXPIRED,
        RP_CANCELED
    }
}
