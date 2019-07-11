use Mix.Config

config :ewallet,
  websocket_endpoints: [EWallet.TestEndpoint],
  node_adapter: {:dumb, DumbAdapter}
