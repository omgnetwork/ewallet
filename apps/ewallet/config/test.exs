use Mix.Config

config :ewallet,
  websocket_endpoints: [EWallet.TestEndpoint],
  eth_node_adapter: {:dumb, EthGethAdapter.DumbAdapter},
  # TODO: update this for tests
  cc_node_adapter: {:elixir_omg, EthElixirOmgAdapterr.Worker}
