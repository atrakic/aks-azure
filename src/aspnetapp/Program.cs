using System.Text.Json.Serialization;
using Microsoft.AspNetCore.HttpOverrides;

using Microsoft.Extensions.DependencyInjection;
using OpenTelemetry.Instrumentation.AspNetCore;
using System.Diagnostics.Metrics;
using OpenTelemetry.Exporter;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);


// Configure OpenTelemetry tracing & metrics with auto-start using the
// AddOpenTelemetry extension from OpenTelemetry.Extensions.Hosting.
var otelExporterOtlpEndpoint = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");
if (!string.IsNullOrEmpty(otelExporterOtlpEndpoint))
{
    var serviceName = Environment.GetEnvironmentVariable("OTEL_SERVICE_NAME") ?? "aspnetapp";

    builder.Logging.AddOpenTelemetry(options =>
    {
        options.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName))
        .AddConsoleExporter();
    });

    builder.Services.AddOpenTelemetry()
        .ConfigureResource(resource => resource.AddService(serviceName))

        .WithTracing(tracing => tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddAspNetCoreInstrumentation()
            // https://github.com/open-telemetry/opentelemetry-dotnet/issues/3753
            //.AddOtlpExporter(exporter => exporter.Endpoint = new Uri(otelExporterOtlpEndpoint))
            .AddConsoleExporter())

        .WithMetrics(metrics => metrics
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddAspNetCoreInstrumentation()
            //.AddOtlpExporter(exporter => exporter.Endpoint = new Uri(otelExporterOtlpEndpoint))
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

//app.UseAuthorization();
//app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();
app.MapHealthChecks("/healthz");

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// Forwarded headers are required for running behind a reverse proxy
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.MapGet("/Environment/{user?}", (string? user) =>
{
    logger.LogInformation(string.IsNullOrEmpty(user) ?
      "Anonymous env" :
      "Environment for {user}", user);
    return new EnvironmentInfo();
});

app.MapGet("/otel", () =>
{
    logger.LogInformation("otel");
    var trace = new OpenTelemetryTrace();
    return trace.GetTrace();
});

CancellationTokenSource cancellation = new();
app.Lifetime.ApplicationStopping.Register(() =>
{
    cancellation.Cancel();
});

app.MapGet("/Delay/{value}", async (int value) =>
{
    try
    {
        value = value > 10000 ? 10000 : value;
        await Task.Delay(value, cancellation.Token);
    }
    catch (TaskCanceledException)
    {
    }
    return new Operation(value);
});

app.Run();

[JsonSerializable(typeof(EnvironmentInfo))]
[JsonSerializable(typeof(Operation))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{
}
public record struct Operation(int Delay);
