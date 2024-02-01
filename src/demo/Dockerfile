ARG VERSION=8.0

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /source

COPY aspnetapp/*.csproj .
RUN dotnet restore

COPY aspnetapp/. .
RUN dotnet publish --no-restore -o /app


FROM mcr.microsoft.com/dotnet/aspnet:${VERSION} as final
EXPOSE 8080
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./aspnetapp"]
