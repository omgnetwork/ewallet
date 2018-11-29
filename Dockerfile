FROM alpine:3.8

LABEL maintainer="OmiseGO Team <omg@omise.co>"
LABEL description="Official image for OmiseGO eWallet"

ENV LANG=C.UTF-8

## S6
##

ENV S6_VERSION="1.21.4.0"

RUN set -xe \
 && apk add --update --no-cache --virtual .fetch-deps \
        curl \
        ca-certificates \
 && S6_DOWNLOAD_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" \
 && S6_DOWNLOAD_SHA256="e903f138dea67e75afc0f61e79eba529212b311dc83accc1e18a449d58a2b10c" \
 && curl -fsL -o s6-overlay.tar.gz "${S6_DOWNLOAD_URL}" \
 && echo "${S6_DOWNLOAD_SHA256}  s6-overlay.tar.gz" |sha256sum -c - \
 && tar -xzC / -f s6-overlay.tar.gz \
 && rm s6-overlay.tar.gz \
 && apk del .fetch-deps

## Application
##

RUN apk add --update --no-cache --virtual .ewallet-runtime \
        bash \
        imagemagick \
        libressl \
        libressl-dev \
        lksctp-tools

COPY rootfs /

ARG user=ewallet
ARG group=ewallet
ARG uid=10000
ARG gid=10000

RUN set -xe \
 && addgroup -g ${gid} ${group} \
 && adduser -D -h /app -u ${uid} -G ${group} ${user} \
 && chown "${uid}:${gid}" "/app" \
 && chmod +x /entrypoint

ARG release_version

ADD _build/prod/rel/ewallet/releases/${release_version}/ewallet.tar.gz /app
RUN chown -R ewallet:ewallet /app
WORKDIR /app

ENV PORT 4000

EXPOSE $PORT
EXPOSE 4369 6900 6901 6902 6903 6904 6905 6906 6907 6908 6909

ENTRYPOINT ["/init", "/entrypoint"]

CMD ["foreground"]
