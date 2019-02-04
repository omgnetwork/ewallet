# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :activity_logger,
  ecto_repos: [ActivityLogger.Repo],
  schemas_to_activity_log_config: %{ActivityLogger.System => %{type: "system", identifier: nil}},
  activity_log_types_to_schemas: %{"system" => ActivityLogger.System}

import_config "#{Mix.env()}.exs"
