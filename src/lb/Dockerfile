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
COPY --from=0 /app/nginx.conf.template /tmp/.nginx.conf.template
CMD ["sh", "-c", "envsubst '${APP_VERSION}' < /tmp/.nginx.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
