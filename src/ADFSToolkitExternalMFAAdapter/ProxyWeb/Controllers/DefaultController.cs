using ADFSTK.ExternalMFA.Common.Facade;
using ADFSTK.ExternalMFA.Common.Interfaces;
using EduIDExternalWeb.Settings;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Text.Json;
using System.Web;

namespace EduIDExternalWeb.Controllers
{
    public class DefaultController : BaseController
    {
        private readonly AppSettings _appSettings;
        private readonly ICryptoService _cryptoService;
        private readonly CryptoSettings _cryptoSettings;
        public DefaultController(AppSettings appSettings,
            ICryptoService cryptoService,
            CryptoSettings cryptoSettings) : base()
        {
            _appSettings = appSettings;
            _cryptoService = cryptoService;
            _cryptoSettings = cryptoSettings;
        }
        
        [IgnoreAntiforgeryTokenAttribute]
        [HttpGet]
        public IActionResult Index([FromQuery]string token)
        {
            if (!string.IsNullOrEmpty(token))
            {
                var decryptedJson = _cryptoService.Base64Decrypt(_cryptoSettings.EncryptionKey, token);
                AuthRequest req = JsonSerializer.Deserialize<AuthRequest>(decryptedJson);

                //Got token, is it valid?
                if (req.AuthInstant < DateTime.UtcNow.AddMinutes(5))
                {
                    SetCookie(token, 5);
                    //redirect according to parameters
                    var r = GetRedirectUrl(req);
                    return Redirect(r);
                }
                else
                {
                    return BadRequest();
                }
            }
            else
            {
                return BadRequest();
            }
            
        }
        private string GetRedirectUrl(AuthRequest request)
        {
            
            return string.Format(_appSettings.GetRedirectUrl(request.Upn),HttpUtility.UrlEncode(request.TargetIdp),request.AuthContextClassRef);
        }

    }
}