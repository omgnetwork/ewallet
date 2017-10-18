FROM gcr.io/omise-go/elixir:latest

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

COPY . /app
WORKDIR /app

RUN MIX_ENV=prod mix do deps.get, compile

ENV PORT 4000
EXPOSE 4000

CMD ["mix", "phx.server"]