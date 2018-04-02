# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  max_per_page: System.get_env("REQUEST_MAX_PER_PAGE") || 100

import_config "#{Mix.env}.exs"
