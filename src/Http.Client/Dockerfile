ARG DOTNET_VERSION=8.0

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build
ARG TARGETARCH
WORKDIR /source

# copy csproj and restore as distinct layers
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH

# copy and publish app and libraries
COPY . .
RUN dotnet publish -a $TARGETARCH --no-restore -o /app

# final stage/image
FROM mcr.microsoft.com/dotnet/runtime:${DOTNET_VERSION}
LABEL org.opencontainers.image.source="https://github.com/atrakic/aks-azure.git"
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./Client"]
