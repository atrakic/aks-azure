using System.Text.Json.Serialization;
using Microsoft.AspNetCore.HttpOverrides;

using Microsoft.Extensions.DependencyInjection;
using OpenTelemetry.Instrumentation.AspNetCore;
using System.Diagnostics;

using System.Diagnostics.Metrics;
using OpenTelemetry.Exporter;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

using aspnetapp.Services;

var builder = WebApplication.CreateBuilder(args);

// Configure OpenTelemetry tracing & metrics with auto-start using the
// AddOpenTelemetry extension from OpenTelemetry.Extensions.Hosting.
var otelExporterOtlpEndpoint = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");
if (!string.IsNullOrEmpty(otelExporterOtlpEndpoint))
{
    var serviceName = Environment.GetEnvironmentVariable("OTEL_SERVICE_NAME") ?? builder.Environment.ApplicationName;

    Action<ResourceBuilder> configureResource = r => r.AddService(
        serviceName: builder.Configuration.GetValue("ServiceName", defaultValue: serviceName)!,
        serviceVersion: typeof(Program).Assembly.GetName().Version?.ToString() ?? "unknown",
        serviceInstanceId: Environment.MachineName);

    // Create a service to expose ActivitySource, and Metric Instruments
    // for manual instrumentation
    builder.Services.AddSingleton<Instrumentation>();

    builder.Logging.ClearProviders();
    builder.Logging.AddOpenTelemetry(options =>
    {
        options.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName))
        .AddConsoleExporter();
    });

    builder.Services.AddOpenTelemetry()
        .ConfigureResource(configureResource)

        .WithTracing(tracing => tracing
            .AddSource(Instrumentation.ActivitySourceName)
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter(exporter => exporter.Endpoint = new Uri(otelExporterOtlpEndpoint))
            .AddConsoleExporter())

        .WithMetrics(metrics => metrics
            // Ensure the MeterProvider subscribes to any custom Meters
            .AddMeter(Instrumentation.MeterName)

            //.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName))
            .AddRuntimeInstrumentation()
            //.AddProcessInstrumentation() // Collects CPU and memory usage (beta)
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter((exporterOptions, metricReaderOptions) =>
            {
                exporterOptions.Endpoint = new Uri(otelExporterOtlpEndpoint);
                exporterOptions.Protocol = OtlpExportProtocol.HttpProtobuf;
                metricReaderOptions.PeriodicExportingMetricReaderOptions.ExportIntervalMilliseconds = 1000 * 2;
            })
            .AddConsoleExporter()
    );
}

builder.Services.AddRazorPages();
builder.Services.AddHealthChecks();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
var logger = app.Logger;

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Forwarded headers are required for running behind a reverse proxy
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

if (!string.IsNullOrEmpty(otelExporterOtlpEndpoint))
{
    //app.UseOpenTelemetryPrometheusScrapingEndpoint();
    app.MapGet("/otel", () => $"OpenTelemetry Trace: {Activity.Current?.Id}");
}

//app.UseAuthorization();
//app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();
app.MapHealthChecks("/healthz");
app.MapControllers();

// --- Environment endpoint ---
app.MapGet("/Environment/{user?}", (string? user) =>
{
    logger.LogInformation(string.IsNullOrEmpty(user) ?
      "Anonymous environment request" :
      "Environment for user {user}", user);
    return new EnvironmentInfo();
});

app.Run();

[JsonSerializable(typeof(EnvironmentInfo))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{
}
