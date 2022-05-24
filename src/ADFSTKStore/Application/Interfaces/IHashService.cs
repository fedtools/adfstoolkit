using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Urn.Adfstk.Application.Domain.Model;

namespace Urn.Adfstk.Application.Interfaces
{
    public interface IHashService
    {
        HashWithSaltResult HashString(string input, string salt);
    }
}
