using ADFSTK.ExternalMFA.Common.Facade;
using ADFSTK.ExternalMFA.Common.Interfaces;
using EduIDExternalWeb.Models;
using EduIDExternalWeb.Settings;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Web;

namespace EduIDExternalWeb.Controllers
{
    public class LoginController : BaseController
    {
        private readonly CryptoSettings _cryptoSettings;
        private readonly ICryptoService _cryptoService;
        public LoginController(ICryptoService cryptoService,
            CryptoSettings cryptoSettings) : base()
        {
            _cryptoService = cryptoService;
            _cryptoSettings = cryptoSettings;
        }
        public IActionResult Index()
        {
            LoginResponseModel model = null;
            //check shib headers and contextclass etc
            // use cookie to fetch authstatus by tokenvalue
            // set IdentityClaimValue (get attribute from authstatus)
            var loginOK = false;
            var dict = new Dictionary<string, string>();
            //var identity = HttpContext.User.Identity as ClaimsIdentity;
            
            foreach (var h in Request.Headers)
            {
                dict.Add(h.Key, h.Value);
            }

            var tokenCookie = GetCookie();
            if (tokenCookie != null)
            {
                var decryptedJson = _cryptoService.Base64Decrypt(_cryptoSettings.EncryptionKey, tokenCookie);
                AuthRequest req = JsonSerializer.Deserialize<AuthRequest>(decryptedJson);
                if (req.AuthInstant < DateTime.UtcNow.AddMinutes(5))
                {
                    if (dict["ShibAuthenticationMethod"].ToLower() == "https://refeds.org/profile/mfa" ||
                        dict["ShibAuthenticationMethod"].ToLower() == "http://schemas.microsoft.com/claims/multipleauthn")
                    {
                        req.IdentityClaimValue = dict[req.IdentityClaimName];
                        var encJson = _cryptoService.Base64Encrypt(_cryptoSettings.EncryptionKey, JsonSerializer.Serialize(req));
                        model = new LoginResponseModel() { Message = HttpUtility.UrlEncode(encJson),OriginIdp=req.OriginIdp.Replace("http://","https://") };
                        loginOK = true;
                        RemoveCookie();
                    }
                }
            }
            if (loginOK)
            {
                return View("FrameSuccess",model);
            }
            else
            {
                return View(dict);
            }
        }
        

        public IActionResult LoginSuccess()
        {
            
            return View();
        }
    }
}