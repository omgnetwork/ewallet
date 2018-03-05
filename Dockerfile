FROM elixir:1.5

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV LIBSODIUM_VERSION="1.0.15"
ENV YARN_VERSION="1.5.1-1"
ENV NODEJS_VERSION="8.x"

RUN set -xe && \
    LIBSODIUM_DOWNLOAD_URL="https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz" && \
    LIBSODIUM_DOWNLOAD_SHA256="fb6a9e879a2f674592e4328c5d9f79f082405ee4bb05cb6e679b90afe9e178f4" && \
    apt-get update && \
    apt-get install -y autoconf autogen build-essential && \
    curl -fSL -o libsodium-src.tar.gz "${LIBSODIUM_DOWNLOAD_URL}" && \
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
    rm -rf /usr/local/src/libsodium

RUN set -xe && \
    NODEJS_SETUP_URL="https://deb.nodesource.com/setup_${NODEJS_VERSION}" && \
    curl -sL $NODEJS_SETUP_URL | bash - && \
    apt-get install -y nodejs

RUN set -xe && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn=$YARN_VERSION

RUN set -xe && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

COPY . /app
WORKDIR /app

RUN set -xe && \
    mix deps.get && \
    MIX_ENV=prod mix compile

RUN set -xe && \
    cd apps/admin_panel/assets && \
    yarn install && \
    yarn build

ENV PORT 4000
EXPOSE 4000

CMD ["mix", "omg.server"]
