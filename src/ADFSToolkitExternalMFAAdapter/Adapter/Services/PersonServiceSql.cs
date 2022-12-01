using ADFSTK.ExternalMFA.Common.Settings;
using ADFSTK.ExternalMFA.Interfaces;
using System;
using System.Data.SqlClient;
using System.Diagnostics;

namespace ADFSTK.ExternalMFA.Services
{
    public class PersonServiceSql : IPersonService
    {
        private SqlSettings _sqlSettings;
        public PersonServiceSql(SqlSettings settings)
        {
            _sqlSettings = settings;
        }
        public string GetUniqueIdentifier(string uid)
        {
            var civicNumber = "";
            EventLog.WriteEntry("AD FS", "Proceeding with GetCivicNumber from SQL ", EventLogEntryType.Information, 335);
            if (uid.Contains("@"))
            {
                uid = uid.Substring(0, uid.IndexOf('@'));
            }
            try
            {
                SqlCommand cmd = new SqlCommand();
                if (uid.ToLower().StartsWith("guest"))
                {
                    cmd.Connection = GetConnection(_sqlSettings.GuestConnStr);
                    cmd.CommandText = _sqlSettings.GuestCmd;
                }
                else
                {
                    cmd.Connection = GetConnection(_sqlSettings.UserConnStr);
                    cmd.CommandText = _sqlSettings.UserCmd;
                }
                cmd.Parameters.AddWithValue("uid", uid);

                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    civicNumber = reader.GetString(0);
                }
                else
                {
                    civicNumber = null;
                }
                reader.Close();
            }
            catch (Exception e)
            {
                EventLog.WriteEntry("AD FS", "Error looking up civicnuber, error " + e.Message, EventLogEntryType.Error, 335);
            }
            return civicNumber;
        }

        public bool UniqueIdentifierValid(string localId, string externalId)
        {
            if (localId.ToLower() == externalId.ToLower())
            {
                return true;
            }
            return false;
        }

        private SqlConnection GetConnection(string connStr)
        {
            var conn = new SqlConnection();
            conn.ConnectionString = connStr;
            conn.Open();
            return conn;
        }
    }
}
