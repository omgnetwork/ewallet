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
    echo 'backtick -in default_host { s6-hostname }' >> $SERVICE_DIR/run && \
    echo 'backtick -in default_cookie { openssl rand -hex 8 }' >> $SERVICE_DIR/run && \
    echo 'importas -iu default_host default_host' >> $SERVICE_DIR/run && \
    echo 'importas -iu default_cookie default_cookie' >> $SERVICE_DIR/run && \
    echo 'importas -D $default_host NODE_HOST NODE_HOST' >> $SERVICE_DIR/run && \
    echo 'importas -D $default_cookie ERLANG_COOKIE ERLANG_COOKIE' >> $SERVICE_DIR/run && \
    echo 'importas -D ewallet NODE_NAME NODE_NAME' >> $SERVICE_DIR/run && \
    echo 'elixir' >> $SERVICE_DIR/run && \
    echo '  --name "${NODE_NAME}@${NODE_HOST}"' >> $SERVICE_DIR/run && \
    echo '  --cookie $ERLANG_COOKIE' >> $SERVICE_DIR/run && \
    echo '  -S mix omg.server --no-watch' >> $SERVICE_DIR/run && \
    echo '#!/bin/execlineb -S1' > $SERVICE_DIR/finish && \
    echo 'if { s6-test ${1} -ne 0 }' >> $SERVICE_DIR/finish && \
    echo 'if { s6-test ${1} -ne 256 }' >> $SERVICE_DIR/finish && \
    echo 's6-svscanctl -t /var/run/s6/services' >> $SERVICE_DIR/finish

ENTRYPOINT ["/init"]