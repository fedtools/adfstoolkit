using ADFSTK.ExternalMFA.Common.Interfaces;
using ADFSTK.ExternalMFA.Common.Services;
//using EduIDExternalWeb.Domain.Interfaces;
//using EduIDExternalWeb.Domain.Managers;
//using EduIDExternalWeb.Infrastructure;
//using EduIDExternalWeb.Service;
using EduIDExternalWeb.Settings;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace EduIDExternalWeb
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            var _appSettings = new AppSettings();
            Configuration.GetSection("AppSettings").Bind(_appSettings);
            services.AddSingleton(_appSettings);
            
            var _cryptoSettings = new CryptoSettings();
            Configuration.GetSection("CryptoSettings").Bind(_cryptoSettings);
            services.AddSingleton<CryptoSettings>(_cryptoSettings);
            services.AddSingleton<ICryptoService, CryptoService>();

            services.AddMvc();
            services.AddControllers();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();
           
            app.UseEndpoints(endpoints =>
            {
                // endpoints.MapControllers();
                endpoints.MapControllerRoute(
                     name: "default",
                     pattern: "{controller=Home}/{action=Index}/{id?}");
                endpoints.MapRazorPages();
            });
        }
    }
}
