# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  max_per_page: {:system, "REQUEST_MAX_PER_PAGE"}

import_config "#{Mix.env()}.exs"
