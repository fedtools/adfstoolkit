using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTK.ExternalMFA.Common.Interfaces
{
    public interface ICryptoService
    {
        string Base64Encrypt(string key, string text);
        string Base64Decrypt(string key, string text);
        string Encrypt(string key, string text);
        string Decrypt(string key, string text);
    }
}
