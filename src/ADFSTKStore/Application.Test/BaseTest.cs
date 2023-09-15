using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IdentityModel;

namespace Urn.Adfstk.Application.Test
{
    public class BaseTest
    {
        
        public Dictionary<string, string> Attributes { get; set; }
        public Dictionary<string,string> InitParams { get; set; }
        //public const string IDPSALT = "f1nd1ngn3m0";
        public const string IDPSALT = "BoelEXUb2qNGNbP7KHy4/q9gHh6ZRc4wvW0lg0Xd";
        public string SPLITPARAM = ",|";
        public BaseTest()
        {
            LoadAttributes();
            System.Threading.Thread.CurrentThread.CurrentCulture = new System.Globalization.CultureInfo("sv-SE");
            System.Threading.Thread.CurrentThread.CurrentUICulture = new System.Globalization.CultureInfo("sv-SE");
            ClassInitialize();
            InitializeParams();
        }
        public static void ClassInitialize()
        {
            foreach (var listener in Trace.Listeners)
            {
                var traceListener = (TraceListener)listener;
                traceListener.TraceOutputOptions = traceListener.TraceOutputOptions | TraceOptions.DateTime;
            }
        }

        private void LoadAttributes()
        {
            Attributes = new Dictionary<string, string>();
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.10", "eduPersonTargetedID");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.6", "eduPersonPrincipalName");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.13", "eduPersonUniqueID");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.16", "eduPersonOrcid");
            Attributes.Add("urn:oid:1.3.6.1.4.1.2428.90.1.5", "norEduPersonNIN");
            Attributes.Add("urn:oid:1.2.752.29.4.13", "personalIdentityNumber");
            Attributes.Add("urn:oid:1.3.6.1.4.1.25178.1.2.3", "schacDateOfBirth");
            Attributes.Add("urn:oid:0.9.2342.19200300.100.1.3", "mail");
            Attributes.Add("urn:oid:2.16.840.1.113730.3.1.241", "displayName");
            Attributes.Add("urn:oid:2.5.4.3", "cn");
            Attributes.Add("urn:oid:2.5.4.42", "givenName");
            Attributes.Add("urn:oid:2.5.4.4", "sn");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.11", "eduPersonAssurance");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.9", "eduPersonScopedAffiliation");
            Attributes.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.1", "eduPersonAffiliation");
            Attributes.Add("urn:oid:2.5.4.10", "o");
            Attributes.Add("urn:oid:1.3.6.1.4.1.2428.90.1.6", "norEduOrgAcronym");
            Attributes.Add("urn:oid:2.5.4.6", "c");
            Attributes.Add("urn:oid:0.9.2342.19200300.100.1.43", "co");
            Attributes.Add("urn:oid:1.3.6.1.4.1.25178.1.2.9", "schacHomeOrganization");
            Attributes.Add("urn:oid:1.3.6.1.4.1.25178.1.2.10", "schacHomeOrganizationType");
            Attributes.Add("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier","PairWiseId");
        }

        private void InitializeParams()
        {
            InitParams = new Dictionary<string, string>();
            InitParams.Add("IDPSALT", IDPSALT);
            //InitParams.Add("SPLITPARAM", SPLITPARAM);
        }

        protected void PrintResult(string[] types, TypedAsyncResult<string[][]> typedResult)
        {
            var yy = typedResult.Result;
            for (int i = 0; i < yy.GetLength(0); i++)
            {
                for (int j = 0; j < yy[i].Length; j++)
                {
                    if (yy[i][j] != null)
                    {
                        Console.Out.WriteLine(types[j] + " (" + Attributes[types[j]] + ") " + yy[i][j]);
                    }
                }
            }
        }
        
    }
}
