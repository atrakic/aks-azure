using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Diagnostics;


public record struct OpenTelemetryTrace
{
    public string GetTrace()
    {
        using var client = new HttpClient();
        var response = client.GetAsync("https://www.bing.com/").Result;
        return $"Hello World! OpenTelemetry Trace: {Activity.Current?.Id}";
    }
}
