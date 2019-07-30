# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :keychain,
  ecto_repos: [Keychain.Repo]

config :block_keys,
  words_list: "#{File.cwd!()}/assets/english.txt"

import_config "#{Mix.env()}.exs"
