using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.IdentityServer.ClaimsPolicy.Engine.AttributeStore;
using System.IdentityModel;
using System.Text;
using ADFSTk.Dto;
using ADFSTk.Interfaces;
using ADFSTk.Impl;
using ADFSTk.Helpers;
using ADFSTk.Utils;
using System.Diagnostics;


namespace ADFSTk
{
    public class ADFSTkStore : IAttributeStore
    {
        private const string IDPSALT = "IDPSALT";
        private const string SPLITPARAM = "SPLITPARAM";

        private string salt;
        private string entityId;
        public string[] separators = new string[] { ",", ";", "|" };

        private IHashService _hashService;
        
        public IAsyncResult BeginExecuteQuery(string query, string[] parameters, AsyncCallback callback, object state)
        {
            CheckDependencies();
            Log.WriteEntry("Start ExecuteQuery",EventLogEntryType.Information,335);
            if (String.IsNullOrEmpty(query))
            {
                Log.WriteEntry("No query string.", EventLogEntryType.Error, 335);
                throw new AttributeStoreQueryFormatException("No query string.");
            }

            if (null == parameters)
            {
                Log.WriteEntry("No query parameter.", EventLogEntryType.Error, 335);
                throw new AttributeStoreQueryFormatException("No query parameter.");
            }

            //just debug
            //foreach (var s in parameters)
            //{
            //    Log.WriteEntry("Parameter: " + s,EventLogEntryType.Information,335);
            //}

            List<ClaimDto> outputValues = null;
            try
            {
                outputValues = new List<ClaimDto>();
                string[] queryParams = GetQueryParams(query);
                Log.WriteEntry("GotQuery" + query, EventLogEntryType.Information, 335);
                string rp = parameters[0];
                string upn = GetUserId(parameters[1]);
                string shacHome = parameters[2];
                
                ClaimDto c = null;
                string param = queryParams.First();
                //foreach (var param in queryParams)
                //{
                    switch (param.ToLower())
                    {
                        case "base32":
                            outputValues.Add(c = new ClaimDto()
                            {
                                Name = param,
                                Values = new List<string> { Base32.ToBase32String(Encoding.Default.GetBytes(upn)) }
                            });
                            break;
                        case "hash":
                            var h = _hashService.HashString(upn, salt);
                            outputValues.Add(c = new ClaimDto()
                            {
                                Name = param,
                                Values = new List<string> { h.DigestHex }
                            });
                            break;
                        case "subjectid":
                            outputValues.Add(c = new ClaimDto()
                            {
                                Name = param,
                                Values = new List<string> { string.Join("@", upn, shacHome.ToLower()) }
                            });
                            break;
                        case "pairwiseid":
                            // first concatenate values
                            var str = string.Join("!", upn, rp);
                            //hash with salt
                            var strHashed = _hashService.HashString(str, salt);
                            //base32 encode
                            var strBase32 = Base32.ToBase32String(Encoding.Default.GetBytes(strHashed.DigestHex));
                            outputValues.Add(c = new ClaimDto() {
                                Name = param, Values = new List<string> {string.Join("@", strBase32,shacHome.ToLower() )} });
                            break;
                        case "edupersonuniqueid":
                        case "urn:mace:dir:attribute-def:edupersonuniqueid":
                            Log.WriteEntry("Transforming eduPersonUniqueID", EventLogEntryType.Information, 335);
                            var hashed = _hashService.HashString(upn, salt);
                            outputValues.Add(c = new ClaimDto()
                            {
                                Name = param,
                                Values = new List<string> { hashed.DigestHex }
                            });
                            break;
                        case "tolower":
                            Log.WriteEntry("Transforming ToLower", EventLogEntryType.Information, 335);
                            outputValues.Add(c = new ClaimDto() { Name = param, Values = new List<string>() { string.IsNullOrEmpty(upn) ? null : upn.ToLower() } });
                            Log.WriteEntry("Transforming ToLower (output=" + outputValues[0].Values.First() + ")", EventLogEntryType.Information, 335);
                            break;
                        case "toupper":
                            Log.WriteEntry("Transforming ToUpper", EventLogEntryType.Information, 335);
                            outputValues.Add(c = new ClaimDto() { Name = param, Values = new List<string>() { string.IsNullOrEmpty(upn) ? null : upn.ToUpper() } });
                            Log.WriteEntry("Transforming ToUpper (output=" + outputValues[0].Values.First() + ")" , EventLogEntryType.Information, 335);
                            break;
                        case "split":
                            Log.WriteEntry("Spliting into multiple claims", EventLogEntryType.Information, 335);
                            foreach(string s in separators)
                            {
                                if (upn.Contains(s))
                                {
                                    string[] temp = upn.Split(new char[] { s.FirstOrDefault() });
                                    outputValues.Add(new ClaimDto() { Name = param, Values = temp.ToList() });
                                }
                            }
                            break;
                        default:
                            break;
                    }
                //foreach}
            }
            catch (Exception ex)
            {
                Log.WriteEntry( "ERROR: " + ex.GetType() + " Message: " + ex.Message + "Stacktrace: " + ex.StackTrace,EventLogEntryType.Error,335);
            }
            TypedAsyncResult<string[][]> asyncResult = new TypedAsyncResult<string[][]>(callback, state);

            asyncResult.Complete(CreateMatrix(outputValues), true);

            if (asyncResult.IsCompleted)
            {
                var xx = (TypedAsyncResult<string[][]>)asyncResult;
            }
            return asyncResult;
        }

        public string[][] EndExecuteQuery(IAsyncResult result)
        {
            return TypedAsyncResult<string[][]>.End(result);
        }

        public void Initialize(Dictionary<string, string> config)
        {
            
            Log.WriteEntry("ADFSTkStore :: starting initialize ...",EventLogEntryType.Information,335);
            //check idpSalt
            if (config.ContainsKey(IDPSALT))
            {
                //Log.WriteEntry("idp salt provided: "+ config[IDPSALT], EventLogEntryType.Information, 335);
                salt = config[IDPSALT];
            }            
            else
            {
                Log.WriteEntry("Error in initialize, no idp salt", EventLogEntryType.Error, 335);
            }
            _hashService = new HashService();
            Log.WriteEntry("ADFSTkStore :: started ...", EventLogEntryType.Information, 335);
            if (config.ContainsKey(SPLITPARAM)){
                //read each splitchar into array
                var temp = new List<string>();
                foreach(char c in config[SPLITPARAM].ToCharArray())
                {
                    temp.Add(c.ToString());
                }
                separators = temp.ToArray();
            }

        }
        #region HelperMethods
        private string[] GetQueryParams(string query)
        {
            var queryParams = new string[] { };
            if (query.Contains(";"))
            {
                var rawQuery = query.Split(';');
                foreach (var q in rawQuery)
                {
                    if (!q.Contains("{"))
                    {
                        if (q.Trim().Length > 0)
                        {
                            queryParams = q.Split(',');
                        }
                    }
                }
            }
            else
            {
                queryParams = new string[] { query.Trim() };
            }
            return queryParams;
        }

        private string GetUserId(string uid)
        {
            if (uid.Contains(@"\"))
            {
                uid = uid.Substring(uid.IndexOf(@"\") + 1);
            }
            if (uid.Contains("@"))
            {
                uid = uid.Substring(uid.IndexOf("@") + 1);
            }

            return uid;
        }

        private string[][] CreateMatrix(List<ClaimDto> input)
        {
            //get the claim with the most values
            var maxClaims = GetMaxClaimNumber(input);
            var output = new string[maxClaims][];
            for (int i = 0; i < maxClaims; i++)
            {
                var c = new string[input.Count];
                for (int j = 0; j < input.Count; j++)
                {
                    c[j] = GetClaimById(input[j], i);
                }
                output[i] = c;
            }
            return output;
        }

        private int GetMaxClaimNumber(List<ClaimDto> input)
        {
            var ret = 0;
            if (input != null)
            {
                ret = input.Any() ? input.Max(z => z.Values.Count) : 0;
            }
            return ret;
        }

        private string GetClaimById(ClaimDto claim, int index)
        {
            string output = null;
            if (index <= (claim.Values.Count - 1))
            {
                output = claim.Values[index];
            }
            return output;
        }

        private void LogOutput(TypedAsyncResult<string[][]> result)
        {
            var yy = result.Result;
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < yy.GetLength(0); i++)
            {
                for (int j = 0; j < yy[i].Length; j++)
                {
                    if (yy[i][j] != "null")
                    {
                        sb.AppendLine("[" + i + "][" + j + "] :: " + yy[i][j]);
                        System.Diagnostics.Debug.WriteLine("[" + i + "][" + j + "] :: " + yy[i][j]);
                    }
                    else
                    {
                        sb.AppendLine("[" + i + "][" + j + "] :: null");
                        System.Diagnostics.Debug.WriteLine("[" + i + "][" + j + "] :: null");
                    }
                }
            }
        }
        private void CheckDependencies()
        {
            if (_hashService == null) { _hashService = new HashService(); }
        }
        #endregion
    }
}
