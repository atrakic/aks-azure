ARG PYTHON_VERSION=alpine

FROM python:${PYTHON_VERSION} as build
WORKDIR /app
ARG HOSTNAMES=
ENV HOSTNAMES=$HOSTNAMES
COPY --chmod=0755 configure.py /usr/local/bin
RUN configure.py


FROM nginx as final
ARG APP_VERSION=0.1.0
ENV APP_VERSION=$APP_VERSION

ARG SERVER_PORT=80
ENV SERVER_PORT=$SERVER_PORT

ARG SERVER_NAME=localhost
ENV SERVER_NAME=$SERVER_NAME

COPY --from=0 /app/nginx.conf.template /etc/nginx/templates/default.conf.template
