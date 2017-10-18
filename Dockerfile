FROM gcr.io/omise-go/elixir:latest

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info

COPY . /app
WORKDIR /app

RUN MIX_ENV=prod mix do deps.get