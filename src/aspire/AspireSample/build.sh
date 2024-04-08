#!/usr/bin/env bash

## https://devblogs.microsoft.com/dotnet/announcing-builtin-container-support-for-the-dotnet-sdk/

## https://github.com/dotnet/sdk/tree/main/src/WebSdk#microsoftnetsdkpublish

## https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/visual-studio-publish-profiles?view=aspnetcore-8.0

## https://github.com/dotnet/sdk-container-builds/blob/main/docs/ZeroToContainer.md

ARGS=() # --os linux --arch x64
dotnet publish $ARGS /p:PublishProfile=DefaultContainer -c Release -p ContainerImageTags='"1.2.3-alpha2;latest"'
