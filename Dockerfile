FROM elixir:1.5

ENV LIBSODIUM_VERSION="1.0.15"
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

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
    mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

COPY . /app
WORKDIR /app

ARG habitus_host
ARG habitus_port

RUN set -xe && \
    mkdir -p ~/.ssh/ && \
    curl -sL -o ~/.ssh/key http://$habitus_host:$habitus_port/v1/secrets/file/ssh_key && \
    curl -sL -o ~/.ssh/config http://$habitus_host:$habitus_port/v1/secrets/file/ssh_config && \
    chmod 600 ~/.ssh/key && \
    mix deps.get && \
    MIX_ENV=prod mix compile && \
    rm -rf ~/.ssh

ENV PORT 4000
EXPOSE 4000

CMD ["mix", "run", "--no-halt"]
