using System;
using System.IdentityModel;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ADFSTk;
namespace Urn.Adfstk.Application.Test
{
    [TestClass]
    public class ClaimTests : BaseTest
    {
        [TestMethod]
        public void SchacDateOfBirthTest()
        {
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "urn:oid:1.3.6.1.4.1.25178.1.2.3" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";schacDateOfBirth;{0}",
                new string[] { "someentityid", "201701012393" }, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual("20170101", x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }
        [TestMethod]
        public void EduPersonUniqueIDTest()
        {
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "urn:oid:1.3.6.1.4.1.5923.1.1.1.13" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";eduPersonUniqueID;{0}",
                new string[] { "someentityid", "1243393890273902" }, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual("bf939d2b61da3d958c1f344473dafbef848757834b1e3fea923b7610de1aa402", x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }
        [TestMethod]
        public void SubjectidTest()
        {
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";subjectid;{0}",
                new string[] { "https://inacademia.org/metadata/inacademia-simple-validation.xml", "student1","umu.se" }, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual("student1@umu.se", x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }
        [TestMethod]
        public void PairWiseIdTest()
        {
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";pairwiseid;{0}",
              new string[] { "https://release-check.swamid.se/shibboleth", "student1", "umu.se" }, null, null); 

              var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual("MM3GMOJQGVTDIN3EGBRDIZRRG4ZTKNTBGNQTSM3EGZSDQOLEGUZTSN3EGEYWENDBGFTGKZDCG4ZDCOJQMFTGMYRTMJQTGNZVGJQTMOI@umu.se", x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }

        [TestMethod]
        public void ToLowerTest()
        {
            var input = "Firstname";
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "urn:oid:2.5.4.42" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";ToLower;{0}",
                new string[] { "someentityid",  input}, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual(input.ToLower(), x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }

        [TestMethod]
        public void ToUpperTest()
        {
            var input = "Firstname";
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "urn:oid:2.5.4.42" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";ToUpper;{0}",
                new string[] { "someentityid", input }, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.AreEqual(input.ToUpper(), x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }

        [TestMethod]
        public void SplitTest()
        {
            var input = "AL1|AL2|AL3";
            var cs = new ADFSTkStore();
            cs.Initialize(this.InitParams);
            var issue = new string[] { "urn:oid:2.5.4.42" };
            IAsyncResult asyncRes =
                cs.BeginExecuteQuery(";Split;{0}",
                new string[] { "someentityid", input, "umu.se" }, null, null);

            var x = (string[][])cs.EndExecuteQuery(asyncRes);

            if (asyncRes.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncRes;
                PrintResult(issue, xx);
                Assert.IsNotNull(x[0][0],"Split not working");
                Assert.AreEqual(3, x.Length);
                Assert.AreEqual("AL1", x[0][0]);
            }
            else
            {
                Assert.Fail();
            }
        }
        
    }
}
