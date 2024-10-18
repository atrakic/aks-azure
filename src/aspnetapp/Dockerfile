ARG DOTNET_VERSION=8.0

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build
WORKDIR /src
COPY . ./
RUN dotnet restore
RUN dotnet publish -c Release --no-restore -o /app


FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION} as final
LABEL org.opencontainers.image.source="https://github.com/atrakic/aks-azure.git"

EXPOSE ${PORT:-5000}
ENV ASPNETCORE_URLS=http://+:${PORT:-5000}

WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./aspnetapp"]
