
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
