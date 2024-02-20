# FROM ubuntu:20.04
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:8.0-bookworm-slim
WORKDIR /home/

COPY . .

ENV DEBIAN_FRONTEND=noninteractive
RUN bash ./setup.sh
#RUN echo '\n' >> "$HOME/.zshrc"
