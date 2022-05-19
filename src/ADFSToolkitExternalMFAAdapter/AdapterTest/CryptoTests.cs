using ADFSTK.ExternalMFA.Common.Facade;
using ADFSTK.ExternalMFA.Common.Interfaces;
using ADFSTK.ExternalMFA.Common.Services;
using System;
using System.Text.Json;
using System.Web;
using Xunit;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class CryptoTests
    {
        private ICryptoService _cryptoService;
        
        private const string EncryptionString = "F-JaNdRgUjXn2r5u8x/A?D(G+KbPeShV";
        public CryptoTests()
        {
            _cryptoService = new CryptoService();
            
        }
        [Fact]
        public void EncryptDecryptStringTest()
        {
            var plainString = "testar lite med encryption";
            var encryptedString = _cryptoService.Encrypt(EncryptionString, plainString);

            var decryptedString = _cryptoService.Decrypt(EncryptionString, encryptedString);

            Assert.Equal(plainString, decryptedString);
        }
        [Fact]
        public void EncryptFrameRequestTest()
        {
            var authRequest = new AuthRequest()
            {
                Token = Guid.NewGuid().ToString(),
                OriginIdp = "http://adfs.umu.se/adfs/services/trust",
                TargetIdp = "http://adfs.umu.se/adfs/services/trust",
                AuthContextClassRef = "http://schemas.microsoft.com/claims/multipleauthn",
                IdentityClaimName = "norEduPersonNIN",
            };
            var json=JsonSerializer.Serialize(authRequest);

            //var base64String = Base64Encode(json);
            //var plainText = Base64Decode(base64String);
            //Assert.Equal(json, plainText);
            //var f = JsonSerializer.Deserialize<FrameAuthRequest>(plainText);




            var encryptedString = _cryptoService.Base64Encrypt(EncryptionString, json);

            var urlencodedEncString = HttpUtility.UrlEncode(encryptedString);

            var urldecodedEncString = _cryptoService.Base64Decrypt(encryptedString,HttpUtility.UrlDecode( urlencodedEncString));
            //var decryptedString = _cryptoService.Decrypt(EncryptionString, urldecodedEncString);

            Assert.Equal(json, urldecodedEncString);
        }
        
    }
}
