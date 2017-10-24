FROM elixir:1.5

RUN set -xe && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

COPY . /app
WORKDIR /app

RUN set -xe && \
    mix deps.get && \
    ENV=prod mix compile

ENV PORT 4000
EXPOSE 4000

CMD ["mix", "phx.server"]