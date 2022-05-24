using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ADFSTk.Domain.Model
{
    public class HashWithSaltResult
    {
        public string Salt { get; }
        public string Digest { get; set; }
        public string DigestHex { get; set; }

        public HashWithSaltResult(string salt)
        {
            Salt = salt;
        }
    }
}
