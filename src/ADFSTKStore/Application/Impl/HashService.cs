using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Urn.Adfstk.Application.Domain.Model;
using Urn.Adfstk.Application.Helpers;
using Urn.Adfstk.Application.Interfaces;

namespace Urn.Adfstk.Application.Impl
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
