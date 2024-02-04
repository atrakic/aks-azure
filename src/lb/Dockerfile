FROM nginx
EXPOSE 8080

ARG APP_SERVER=foo.bar.com
ENV APP_SERVER=$APP_SERVER

ARG APP_VERSION=0.1.0
ENV APP_VERSION=$APP_VERSION

COPY nginx.conf /tmp/nginx.conf.template
CMD ["sh", "-c", "envsubst '${APP_VERSION},${APP_SERVER}' < /tmp/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
