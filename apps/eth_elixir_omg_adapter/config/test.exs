use Mix.Config

config :eth_elixir_omg_adapter,
  contract_address:
    {:system, "ELIXIR_OMG_CONTRACT_ADDRESS", "0x316d3e9d574e91fd272fd24fb5cb7dfd4707a571"},
  childchain_url: {:system, "ELIXIR_OMG_CHILDCHAIN_URL", "http://localhost:8082"},
  watcher_url: {:system, "ELIXIR_OMG_WATCHER_URL", "http://localhost:8081"}
