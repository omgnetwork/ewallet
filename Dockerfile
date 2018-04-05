FROM omisegoimages/ewallet-base:1.6-otp20-stretch

COPY . /app
WORKDIR /app

RUN set -xe && \
    groupadd -r ewallet && \
    useradd -r -g ewallet ewallet && \
    chown -R ewallet /app

RUN set -xe && \
    rm -f /etc/apt/sources.list.d/chris-lea-node_js-stretch.list && \
    curl -fsL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    curl -fsL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn && \
    execlineb -P -c " \
        s6-setuidgid ewallet \
        s6-env HOME=/tmp/ewallet \
        cd /app/apps/admin_panel/assets \
        if { yarn install } \
        if { yarn build } \
        rm -rf node_modules \
        rm -rf /tmp/ewallet \
    " && \
    apt-get remove -y nodejs yarn && \
    apt-get clean && \
    rm -rf /etc/apt/sources.list.d/nodesource.list && \
    rm -rf /etc/apt/sources.list.d/yarn.list

RUN set -xe && \
    execlineb -P -c " \
        s6-setuidgid ewallet \
        s6-env HOME=/tmp/ewallet \
        s6-env MIX_ENV=prod \
        if { mix local.hex --force } \
        if { mix local.rebar --force } \
        if { mix deps.get } \
        mix compile \
        rm -rf /tmp/ewallet"

ENV ERLANG_COOKIE default
ENV PORT 4000
EXPOSE 4000

RUN set -xe && \
    SERVICE_DIR=/etc/services.d/ewallet/ && \
    mkdir -p "$SERVICE_DIR" && \
    echo '#!/bin/execlineb -P' > $SERVICE_DIR/run && \
    echo 'with-contenv' >> $SERVICE_DIR/run && \
    echo 'cd /app' >> $SERVICE_DIR/run && \
    echo 's6-setuidgid ewallet' >> $SERVICE_DIR/run && \
    echo 's6-env HOME=/tmp/ewallet' >> ${SERVICE_DIR}/run && \
    echo 's6-env MIX_ENV=prod' >> $SERVICE_DIR/run && \
    echo 'foreground {' >> $SERVICE_DIR/run && \
    echo '  importas -i ERLANG_COOKIE ERLANG_COOKIE' >> $SERVICE_DIR/run && \
    echo '  redirfd -w 1 /tmp/ewallet/.erlang.cookie' >> $SERVICE_DIR/run && \
    echo '  s6-echo -n $ERLANG_COOKIE' >> $SERVICE_DIR/run && \
    echo '}' >> $SERVICE_DIR/run && \
    echo 's6-chmod 0400 /tmp/ewallet/.erlang.cookie' >> $SERVICE_DIR/run && \
    echo 'mix omg.server --no-watch' >> $SERVICE_DIR/run && \
    echo '#!/bin/execlineb -S1' > $SERVICE_DIR/finish && \
    echo 'if { s6-test ${1} -ne 0 }' >> $SERVICE_DIR/finish && \
    echo 'if { s6-test ${1} -ne 256 }' >> $SERVICE_DIR/finish && \
    echo 's6-svscanctl -t /var/run/s6/services' >> $SERVICE_DIR/finish

ENTRYPOINT ["/init"]