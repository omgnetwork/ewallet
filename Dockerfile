FROM elixir:1.6

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

ENV S6_VERSION="1.21.4.0"

RUN set -xe && \
    S6_DOWNLOAD_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" && \
    S6_DOWNLOAD_SHA256="e903f138dea67e75afc0f61e79eba529212b311dc83accc1e18a449d58a2b10c" && \
    curl -fsL -o s6-overlay.tar.gz "${S6_DOWNLOAD_URL}" && \
    echo "${S6_DOWNLOAD_SHA256}  s6-overlay.tar.gz" |sha256sum -c - && \
    tar -xzC / -f s6-overlay.tar.gz && \
    rm s6-overlay.tar.gz

ENV LIBSODIUM_VERSION="1.0.15"

RUN set -xe && \
    LIBSODIUM_DOWNLOAD_URL="https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz" && \
    LIBSODIUM_DOWNLOAD_SHA256="fb6a9e879a2f674592e4328c5d9f79f082405ee4bb05cb6e679b90afe9e178f4" && \
    apt-get update && \
    apt-get install -y autoconf autogen build-essential && \
    curl -fsL -o libsodium-src.tar.gz "${LIBSODIUM_DOWNLOAD_URL}" && \
    echo "$LIBSODIUM_DOWNLOAD_SHA256  libsodium-src.tar.gz" | sha256sum -c - && \
    mkdir -p /usr/local/src/libsodium && \
    tar -xzC /usr/local/src/libsodium --strip-components=1 -f libsodium-src.tar.gz && \
    rm libsodium-src.tar.gz && \
    cd /usr/local/src/libsodium && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make check && \
    make install && \
    apt-get remove -y autoconf autogen build-essential && \
    apt-get clean && \
    rm -rf /usr/local/src/libsodium

RUN set -xe && \
    SERVICE_PATH=/etc/services.d/ewallet && \
    mkdir -p $(dirname "$SERVICE_PATH") && \
    echo '#!/bin/execlineb -P' > $SERVICE_PATH && \
    echo 's6-env MIX_ENV prod cd /app mix omg.server --no-watch' >> $SERVICE_PATH

COPY . /app
WORKDIR /app

RUN set -xe && \
    apt-get update && \
    apt-get install -y apt-transport-https && \
    rm -f /etc/apt/sources.list.d/chris-lea-node_js-stretch.list && \
    curl -fsL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    curl -fsL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn && \
    cd /app/apps/admin_panel/assets && \
    yarn install && \
    yarn build && \
    rm -rf /app/apps/admin_panel/node_modules && \
    apt-get remove -y apt-transport-https nodejs yarn && \
    apt-get clean && \
    rm -rf /etc/apt/sources.list.d/nodesource.list && \
    rm -rf /etc/apt/sources.list.d/yarn.list

RUN set -xe && \
    MIX_ENV=prod && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

ENV PORT 4000
EXPOSE 4000

ENTRYPOINT ["/init"]