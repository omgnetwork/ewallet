# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :eth_elixir_omg_adapter,
  contract_address:
    {:system, "ELIXIR_OMG_CONTRACT_ADDRESS", "0x1fb01c432755298fdd1a7c6aadfdf6124f2e915c"},
  childchain_url: {:system, "ELIXIR_OMG_CHILDCHAIN_URL", "http://localhost:9656"},
  watcher_url: {:system, "ELIXIR_OMG_WATCHER_URL", "http://localhost:7434"}

import_config "#{Mix.env()}.exs"
