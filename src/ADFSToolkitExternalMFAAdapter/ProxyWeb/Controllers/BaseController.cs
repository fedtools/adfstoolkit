using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;

namespace EduIDExternalWeb.Controllers
{
    public class BaseController : Controller
    {
        private const string COOKIENAME = "EXTERNALREFEDSAUTH";
        /// <summary>  
        /// set the cookie  
        /// </summary>  
        /// <param name="value">value to store in cookie object</param>  
        /// <param name="expireTime">expiration time</param>  
        public void SetCookie(string value, int? expireTime)
        {
            CookieOptions option = new CookieOptions();

            if (expireTime.HasValue)
                option.Expires = DateTime.Now.AddMinutes(expireTime.Value);
            else
                option.Expires = DateTime.Now.AddMilliseconds(10);

            Response.Cookies.Append(COOKIENAME, value, option);
        }
        /// <summary>  
        /// Delete the key  
        /// </summary>  
        public void RemoveCookie()
        {
            Response.Cookies.Delete(COOKIENAME);
        }
        public string GetCookie()
        {
            var cookieValue = Request.Cookies[COOKIENAME];
            return cookieValue;
        }
    }
}
