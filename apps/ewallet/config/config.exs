# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  base_url: {:system, "BASE_URL", "http://localhost:4000"},
  max_per_page: {:system, "REQUEST_MAX_PER_PAGE"}

# Configs for Bamboo emailing library
config :ewallet, EWallet.Mailer, adapter: Bamboo.LocalAdapter

import_config "#{Mix.env()}.exs"
