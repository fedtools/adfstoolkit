using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace ADFSTK.ExternalMFA.AdapterTest
{
    public class BaseTest
    {
       

        public static IServiceCollection services = new ServiceCollection();
        public static ServiceProvider provider;
        public static IConfiguration Configuration;
        public const string TOKEN = "77A28730-3E39-425D-BB23-F598577ED081";
        public const string UPN = "user1234@umu.se";
        public const string IDP = "http://adfs.xx.se/adfs/services/trust";
        public const string IDENTITYCLAIM = "norEduPersonNIN";
        public const string IDENTITYCLAIMVALUE = "191212121212";
        public const string PROXYSP = "https://proxy.se/Default/Index/";
        public const string PERSONSERVICEIMPL = "LDAP";
        public BaseTest()
        {

            Configure();
            var s = services.BuildServiceProvider();
            
        }
        private void Configure()
        {             
            services.AddSingleton<IConfiguration>(Configuration);
        }

        private static IConfiguration InitConfiguration()
        {
            var config = new ConfigurationBuilder()
                    .AddJsonFile("appsettings.json")
                    .Build();
            return config;
        }
        
       
       
    }
}
