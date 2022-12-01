using ADFSTK.ExternalMFA.Common.Facade;
using ADFSTK.ExternalMFA.Common.Interfaces;
using ADFSTK.ExternalMFA.Common.Services;
using ADFSTK.ExternalMFA.Common.Settings;
using ADFSTK.ExternalMFA.Interfaces;
using ADFSTK.ExternalMFA.Services;
using Microsoft.IdentityServer.Web.Authentication.External;
using Newtonsoft.Json;
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Runtime.Serialization.Json;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Web;
using Claim = System.Security.Claims.Claim;

namespace ADFSTK.ExternalMFA
{
    public class ExternalRefedsMFAAdapter : IAuthenticationAdapter
    {
       
        public IPersonService _personService;
        public ICryptoService _cryptoService;

        private static ExternalMFASettings _externalMFASettings { get; set; }
        protected IAdapterPresentationForm CreateAdapterPresentation(string username, string proxyUrl,string trustedUrl)
        {
            return new ExternalReefedsPresentation(username, proxyUrl,trustedUrl);
        }
        protected IAdapterPresentationForm CreateAdapterPresentationOnError(string username, string secret, ExternalAuthenticationException ex)
        {
            return new ExternalReefedsPresentation(username, secret, ex);
        }

        #region IAuthenticationAdapter Members
        public IAuthenticationAdapterMetadata Metadata => new ExternalRefedsMFAMetadata();
        public IAdapterPresentation BeginAuthentication(Claim identityClaim, HttpListenerRequest request, IAuthenticationContext authContext)
        {
            if (null == identityClaim) throw new ArgumentNullException(nameof(identityClaim));

            if (null == authContext) throw new ArgumentNullException(nameof(authContext));

            if (String.IsNullOrEmpty(identityClaim.Value))
            {
                throw new InvalidDataException(ResourceHandler.GetResource(Constants.ResourceNames.ErrorNoUserIdentity, authContext.Lcid));
            }
            EventLog.WriteEntry("AD FS", "Getting logipage: ", EventLogEntryType.Information, 335);
            var secret = Guid.NewGuid().ToString();

            //create token
            var authRequest = new AuthRequest()
            {
                Token = secret,
                OriginIdp = _externalMFASettings.OriginIdp,
                TargetIdp = _externalMFASettings.TargetIdp,
                AuthContextClassRef = _externalMFASettings.AuthContextClassRef,
                IdentityClaimName = _externalMFASettings.IdentityClaimName,
            };

            // save the current user ID in the encrypted blob.
            EventLog.WriteEntry("AD FS", "Saving to context ", EventLogEntryType.Information, 335);
            authContext.Data.Add(Constants.AuthContextKeys.Identity, identityClaim.Value);
            authContext.Data.Add(Constants.AuthContextKeys.Token, secret);

            var json = JsonConvert.SerializeObject(authRequest);
            var encryptedJson = _cryptoService.Base64Encrypt(_externalMFASettings.CryptoKey, json);
            EventLog.WriteEntry("AD FS", "encrypted object: ", EventLogEntryType.Information, 335);
            var url = _externalMFASettings.ProxySp + "?token=" + HttpUtility.UrlEncode(encryptedJson);            
            var trustedUrl = GetTrustedUri( _externalMFASettings.ProxySp);
            EventLog.WriteEntry("AD FS", "Getting trustedurl from: " + _externalMFASettings.ProxySp + ", Got: " + trustedUrl, EventLogEntryType.Information, 335);
            EventLog.WriteEntry("AD FS", "Getting loginpage: ", EventLogEntryType.Information, 335);
            return CreateAdapterPresentation(identityClaim.Value, url,trustedUrl);
        }
        public bool IsAvailableForUser(Claim identityClaim, IAuthenticationContext context)
        {
            return true;
        }

        public IAdapterPresentation OnError(HttpListenerRequest request, ExternalAuthenticationException ex)
        {
            if (ex == null)
            {
                throw new ArgumentNullException(nameof(ex));
            }
            return CreateAdapterPresentationOnError(String.Empty, "secret", ex);
        }

        public void OnAuthenticationPipelineLoad(IAuthenticationMethodConfigData configData)
        {
            // Get ConfigData
            if (configData != null)
            {
                if (configData.Data != null)
                {
                    using (StreamReader reader = new StreamReader(configData.Data, Encoding.UTF8))
                    {
                        //Config should be in a json format, and needs to be registered with the 
                        //-ConfigurationFilePath parameter when registering the MFA Adapter (Register-AdfsAuthenticationProvider cmdlet)
                        try
                        {
                            var config = reader.ReadToEnd();
                            var js = new DataContractJsonSerializer(typeof(ExternalMFASettings));
                            var ms = new MemoryStream(UTF8Encoding.UTF8.GetBytes(config));
                            var mfaConfig = (ExternalMFASettings)js.ReadObject(ms);
                            _externalMFASettings = mfaConfig;
                        }
                        catch (Exception ex)
                        {
                            EventLog.WriteEntry("AD FS", "Unable to load ExternalMFA config data. Check that it is registered and correct." + ex.Message + ex.StackTrace, EventLogEntryType.Information, 335);
                            throw new ArgumentException();
                        }
                    }
                    try
                    {
                        if (_externalMFASettings != null)
                        {
                            _cryptoService = new CryptoService();
                           
                           
                            switch (_externalMFASettings.PersonServiceImpl.ToUpper())
                            {
                                case "SQL":
                                    if (_externalMFASettings.SqlConfig != null)
                                    {
                                        //Use default service
                                        _personService = new PersonServiceSql(_externalMFASettings.SqlConfig);
                                    }
                                    break;
                                case "LDAP":
                                    if (_externalMFASettings.LdapConfig != null)
                                    {
                                        //Set up LdapService provided
                                        _personService = new PersonServiceLdap(_externalMFASettings.LdapConfig);
                                    }
                                    break;
                                case "MOCK":
                                    _personService = new PersonServiceMock();
                                    break;
                            }
                        }
                        else
                        {
                            EventLog.WriteEntry("AD FS", "No Settings provided for ExternalIdpMFAAdapter", EventLogEntryType.Error, 335);
                        }
                    }
                    catch (Exception ex)
                    {
                        EventLog.WriteEntry("AD FS", "Unable to configure ExternalIdpMFAAdapter " + ex.Message + ex.StackTrace, EventLogEntryType.Error, 335);
                        throw new ArgumentException();
                    }
                }
            }
            else
            {
                throw new ArgumentNullException();
            }
        }

        public void OnAuthenticationPipelineUnload()
        {
        }
        public IAdapterPresentation TryEndAuthentication(IAuthenticationContext authContext, IProofData proofData, HttpListenerRequest request, out Claim[] outgoingClaims)
        {
            EventLog.WriteEntry("AD FS", "Entering ExternalIdpMFAAdapter TryEndAuthentication", EventLogEntryType.Information, 335);
            if (null == authContext)
            {
                throw new ArgumentNullException(nameof(authContext));
            }

            outgoingClaims = new Claim[0];

            if (!authContext.Data.ContainsKey(Constants.AuthContextKeys.Identity))
            {
                EventLog.WriteEntry("AD FS", "ExternalIdpMFAAdapter identity not present ", EventLogEntryType.Error, 335);
                Trace.TraceError(string.Format("TryEndAuthentication Context does not contains userID."));
                throw new ArgumentOutOfRangeException(Constants.AuthContextKeys.Identity);
            }

            if (!authContext.Data.ContainsKey(Constants.AuthContextKeys.Token))
            {
                EventLog.WriteEntry("AD FS", "ExternalIdpMFAAdapter, Token not present ", EventLogEntryType.Error, 335);
                throw new ArgumentNullException(Constants.AuthContextKeys.Token);
            }

            string view = (string)proofData.Properties[Constants.PropertyNames.View];
            EventLog.WriteEntry("AD FS", "TryEndAuthentication View: " + view, EventLogEntryType.Information, 335);
            if (view == Constants.ResourceNames.ViewStart)
            {
                //Get token;
                string token = (string)authContext.Data[Constants.AuthContextKeys.Token];
                EventLog.WriteEntry("AD FS", "Got token: " + token, EventLogEntryType.Information, 335);
                var urldecodedEncString = _cryptoService.Base64Decrypt(_externalMFASettings.CryptoKey, HttpUtility.UrlDecode((string)proofData.Properties["ExternalResponse"]));
                EventLog.WriteEntry("AD FS", "Decrypted token: " + urldecodedEncString, EventLogEntryType.Information, 335);
                var authResponse = JsonConvert.DeserializeObject<AuthRequest>(urldecodedEncString);
                EventLog.WriteEntry("AD FS", "Got uniqueidentifier from proxy: " + authResponse.IdentityClaimValue, EventLogEntryType.Information, 335);
                
                //Check valid time, valid user etc
                if(authResponse!=null)
                {
                    EventLog.WriteEntry("AD FS", "Authreq not null: ", EventLogEntryType.Information, 335);
                    //valid time?
                    if (authResponse.AuthInstant < DateTime.UtcNow.AddMinutes(5))
                    {
                        EventLog.WriteEntry("AD FS", "Get unique identifier from personservice: ", EventLogEntryType.Information, 335);
                        var ssn = _personService.GetUniqueIdentifier((string)authContext.Data[Constants.AuthContextKeys.Identity]);
                        EventLog.WriteEntry("AD FS", "Got unique identifier from personservice: ", EventLogEntryType.Information, 335);
                        //valid token and ssn
                        if (token == authResponse.Token && _personService.UniqueIdentifierValid(ssn, authResponse.IdentityClaimValue))
                        {
                            EventLog.WriteEntry("AD FS", "token valid, unique identifier valid: ", EventLogEntryType.Information, 335);
                            outgoingClaims = new Claim[]
                            {
                                new Claim(Constants.AuthenticationMethodClaimType, Constants.RefedsMFA)
                            };
                        }
                    }
                    
                }
                else
                {
                    return CreateAdapterPresentationOnError("", "", new ExternalAuthenticationException("Error logging in with ExternalMFA", authContext));
                }
                
            }

            if (outgoingClaims.Length > 0)
            {
                return null;
            }
            else
            {
                return CreateAdapterPresentationOnError("", "", new ExternalAuthenticationException("Error logging in with ExternalMFA", authContext));
            }

        }
        #endregion
        public string GetTrustedUri(string proxyUrl)
        {
            var uri = new Uri(proxyUrl);
            var trusted = uri.GetLeftPart(UriPartial.Authority); 
            return trusted;
        }
    }
}

