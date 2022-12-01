using ADFSTk.Domain.Model;

namespace ADFSTk.Interfaces
{
    public interface IHashService
    {
        HashWithSaltResult HashString(string input, string salt);
    }
}
