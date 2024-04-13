ARG DOTNET_VERSION=8.0
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o out
