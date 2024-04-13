ARG DOTNET_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}
LABEL org.opencontainers.image.source="https://github.com/atrakic/aks-azure.git"
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o out
