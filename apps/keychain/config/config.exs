# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :keychain,
  ecto_repos: [Keychain.Repo]

import_config "#{Mix.env()}.exs"
