using ADFSTK.ExternalMFA.Common.Settings;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LdapTest
{
    public class Program
    {
        static void Main(string[] args)
        {
            LdapSettings settings = new LdapSettings()
            {
                UserName = "",
                Password = "",
                SearchRoot = "LDAP://dc=utvad,dc=umu,dc=se",
                Filter = "(&(objectClass=user)(sAMAccountName={0}))",
                AttributeToRetrieve = "employeeID"
            };
            LdapTest app = new LdapTest(settings);
            try
            {
                var ssn = app.GetCivicNumber("toylon98");
                Console.Out.WriteLine(ssn);
            }
            catch (Exception e)
            {
                Console.Out.WriteLine(e.Message);
                    Console.Out.WriteLine(e.StackTrace);
                throw;
            }

            Console.ReadKey();
        }
    }
}
