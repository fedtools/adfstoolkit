using System;
using System.Collections.Generic;
using System.Text;
using Xunit;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class StringTests :BaseTest
    {
        [Fact]
        public void GetUriBasePartTest()
        {
            var uri = new Uri(PROXYSP);
            var host = uri.Host;
            var trusted = string.Join(string.Empty, uri.Scheme, "://", uri.Host);
            Assert.Equal("https://client200-180.its.umu.se", trusted);
        }
    }
}
