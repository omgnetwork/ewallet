# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :activity_logger,
  ecto_repos: [ActivityLogger.Repo]

import_config "#{Mix.env()}.exs"
