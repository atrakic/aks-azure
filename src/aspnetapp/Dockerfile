ARG VERSION=8.0

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /src
COPY . ./
RUN dotnet restore
RUN dotnet publish -c Release --no-restore -o /app

FROM mcr.microsoft.com/dotnet/aspnet:${VERSION} as final
LABEL org.opencontainers.image.source="https://github.com/atrakic/aks-azure.git"
EXPOSE 8080
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./aspnetapp"]
