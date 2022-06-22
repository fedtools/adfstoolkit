using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ADFSTk.Helpers;
using System.Text;
using System.Text.RegularExpressions;


namespace Urn.Adfstk.Application.Test
{
    [TestClass]
    public class StringTests :BaseTest
    {
        

        [TestMethod]
        public void Base32Test()
        {
            //var input = "student1!https://inacademia.org/metadata/inacademia-simple-validation.xml";
            var input = "student1";
            var output = Base32.ToBase32String(Encoding.UTF8.GetBytes(input));
            Assert.AreEqual("ON2HKZDFNZ2DC", output);
            var expected = Encoding.UTF8.GetString(Base32.FromBase32String(output));
            expected = Regex.Replace(expected, "\0", String.Empty);
            Assert.AreEqual(input, expected);
            
        }

        [TestMethod]
        public void Base32DecodeTest()
        {
            var input = "ON2HKZDFNZ2DC";
            var output = Base32.FromBase32String(input);
            var expected = Encoding.UTF8.GetString(output);
            expected = Regex.Replace(expected, "\0", String.Empty);
            Assert.AreEqual(expected, "student1");
        }

        [TestMethod]
        public void StringWithSaltHasherTest()
        {
            var h = new StringWithSaltHasher();
            var output = h.HashWithSalt(@"student1!https://inacademia.org/metadata/inacademia-simple-validation.xml", IDPSALT);
            //var output = h.HashWithSalt("student1", IDPSALT);
            Assert.AreEqual(IDPSALT, output.Salt);
            Assert.AreEqual("75a212240fb4649dcdf42de771ab7b63c8bd30e18fa1edcdeffbbab5dfe0f90a", output.DigestHex);
        }

        [TestMethod]
        public void InitParamTest()
        {
            foreach (var entry in InitParams)
            {
                Console.Out.WriteLine(string.Format("Key:{0}, Value:{1}", entry.Key, entry.Value));
            }
            Assert.AreEqual(1, InitParams.Count);
        }
    }
}

