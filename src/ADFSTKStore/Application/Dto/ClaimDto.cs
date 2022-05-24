using System.Collections.Generic;
using System.Linq;

namespace Urn.Adfstk.Application.domain.model
{
    public class ClaimDto
    {
        public ClaimDto()
        {
            Values = new List<string>();
        }
        public string Name { get; set; }
        public List<string> Values { get; set; }

        public string[] GetClaimString()
        {
            var c = Values.Aggregate("", (current, s) => current + (s + ";"));
            return new string[] { c.TrimEnd(new char[';']) };
        }
    }
}
