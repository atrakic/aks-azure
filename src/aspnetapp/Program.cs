using System.Text.Json.Serialization;
using Microsoft.AspNetCore.HttpOverrides;

using System.Globalization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddHealthChecks();

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

app.MapGet("/Environment", () =>
{
    logger.LogInformation("Environment");
    return new EnvironmentInfo();
});

app.MapGet("/rolldice/{player?}", (string? player) =>
{
    var result = Random.Shared.Next(1, 7);
    var message = string.IsNullOrEmpty(player)
        ? $"Anonymous player is rolling the dice: {result}"
        : $"{player} is rolling the dice: {result}";

    logger.LogInformation(message);
    return result.ToString(CultureInfo.InvariantCulture);
});

app.Run();

[JsonSerializable(typeof(EnvironmentInfo))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{
}
