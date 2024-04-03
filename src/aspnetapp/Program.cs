using System.Text.Json.Serialization;
using Microsoft.AspNetCore.HttpOverrides;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddHealthChecks();
//builder.Services.AddOpenTelemetry().UseAzureMonitor();

var app = builder.Build();

app.MapHealthChecks("/healthz");

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

//app.UseHttpsRedirection();
app.UseStaticFiles();

// Forwarded headers are required for running behind a reverse proxy
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.UseRouting();
//app.UseAuthorization();
app.MapRazorPages();

CancellationTokenSource cancellation = new();
app.Lifetime.ApplicationStopping.Register(() =>
{
    cancellation.Cancel();
});

app.MapGet("/Environment", () =>
{
    return new EnvironmentInfo();
});


app.MapGet("/otel", () =>
{
    app.Logger.LogInformation("otel");
    var trace = new OpenTelemetryTrace();
    return trace.GetTrace();
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
