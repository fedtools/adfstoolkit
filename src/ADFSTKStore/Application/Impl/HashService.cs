using ADFSTk.Domain.Model;
using ADFSTk.Helpers;
using ADFSTk.Interfaces;

namespace ADFSTk.Impl
{
    public class HashService : IHashService
    {
       
        public HashWithSaltResult HashString(string input,string salt)
        {
            var hasher = new StringWithSaltHasher();
            return hasher.HashWithSalt(input, salt);
        }


    }
}
