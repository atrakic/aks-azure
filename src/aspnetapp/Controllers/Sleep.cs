using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json.Serialization;

namespace aspnetapp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SleepController : ControllerBase
    {
        [HttpGet]
        public async Task<Operation> Sleep(int milliseconds)
        {
            const int sleepMaxDelay = 1000 * 3; // 3 seconds
            milliseconds = milliseconds > sleepMaxDelay ? sleepMaxDelay : milliseconds;
            //logger.LogInformation("Sleep: {milliseconds}", milliseconds);
            await Task.Delay(milliseconds);
            return new Operation(milliseconds);
        }
    }
    public record struct Operation(int Delay);
}
