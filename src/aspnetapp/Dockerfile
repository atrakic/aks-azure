ARG VERSION=8.0

FROM mcr.microsoft.com/dotnet/sdk:${VERSION} AS build
WORKDIR /src
COPY . ./
RUN dotnet restore
RUN dotnet publish -c Release --no-restore -o /app


FROM mcr.microsoft.com/dotnet/aspnet:${VERSION} as final
LABEL org.opencontainers.image.source="https://github.com/atrakic/aks-azure.git"
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# install OpenTelemetry .NET Automatic Instrumentation
ARG OTEL_VERSION=1.4.0
ADD https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v${OTEL_VERSION}/otel-dotnet-auto-install.sh otel-dotnet-auto-install.sh
RUN apt-get update && apt-get install -y curl unzip && \
    OTEL_DOTNET_AUTO_HOME="/otel-dotnet-auto" sh otel-dotnet-auto-install.sh

WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./aspnetapp"]
