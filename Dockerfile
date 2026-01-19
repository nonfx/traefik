# syntax=docker/dockerfile:1.2
FROM alpine:3.23

# Upgrade packages to fix stdlib and other vulnerabilities
# Update to latest Alpine 3.23 packages including OpenSSL and other security fixes
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache --no-progress ca-certificates tzdata wget && \
    apk upgrade --no-cache

ARG TARGETPLATFORM
COPY ./dist/$TARGETPLATFORM/traefik /

EXPOSE 80
VOLUME ["/tmp"]

ENTRYPOINT ["/traefik"]
