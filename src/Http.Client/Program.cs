using System.Diagnostics;

using OpenTelemetry;
using OpenTelemetry.Resources;

using OpenTelemetry.Trace;
using OpenTelemetry.Logs;

internal class Program
{
    private static readonly ActivitySource MyActivitySource = new(nameof(Program));
    private static async Task<int> Main(string[] args)
    {
        if (args.Length != 1)
        {
            Console.WriteLine(@"Error: URL missing");
            return 2;
        }

        var tracerProvider = Sdk.CreateTracerProviderBuilder()
              .AddHttpClientInstrumentation()
              .ConfigureResource(r => r.AddService(Environment.GetEnvironmentVariable("OTEL_SERVICE_NAME") ?? nameof(Program)))
              .AddSource(nameof(Program))
              .SetErrorStatusOnException()          // Record exceptions as errors
              .SetSampler(new AlwaysOnSampler())    // Sample all telemetry (useful for testing)
              .AddConsoleExporter()
              .AddOtlpExporter(opt =>
                {
                    var endpoint = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");
                    if (!string.IsNullOrEmpty(endpoint))
                    {
                        opt.Endpoint = new Uri(endpoint);
                    }
                    Console.WriteLine($"OTLP Exporter is using endpoint {opt.Endpoint}");
                })
              .Build();

        const int SLEEP = 5000;
        var url = args[0];
        using var httpClient = new HttpClient();
        httpClient.DefaultRequestHeaders.Add("User-Agent", "OpenTelemetryHttpClient");

        while (true)
        {
            using var activity = MyActivitySource.StartActivity("GetRequest");
            try
            {
                var content = await httpClient.GetStringAsync(url);
                Console.WriteLine(content);
                activity?.SetStatus(ActivityStatusCode.Ok);
            }
            catch (HttpRequestException ex)
            {
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity?.RecordException(ex);
                Console.WriteLine(ex);
            }
            Thread.Sleep(SLEEP);
        }

        // Dispose tracer provider before the application ends.
        // This will flush the remaining spans and shutdown the tracing pipeline.
        //tracerProvider.Dispose();
    }
}
