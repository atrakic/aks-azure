using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Linq;

namespace aspnetapp.Pages
{
    public class UserInfoModel : PageModel
    {
        public string? RemoteIp { get; set; }
        public List<string?>? RequestHeaders { get; set; }

        public void OnGet()
        {
            RemoteIp = Request.HttpContext.Connection.RemoteIpAddress?.ToString();
            RequestHeaders = Request.Headers.Select(x => x.Value.FirstOrDefault()).ToList();
        }

        public void OnPost()
        {
            // Logic for handling POST request
        }
    }
}
