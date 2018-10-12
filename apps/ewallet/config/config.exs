# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  sender_email: {:system, "SENDER_EMAIL", "admin@localhost"},
  redirect_url_prefixes: {:system, "REDIRECT_URL_PREFIXES", ""}

# Configs for Bamboo emailing library
config :ewallet, EWallet.Mailer, adapter: Bamboo.LocalAdapter

import_config "#{Mix.env()}.exs"
