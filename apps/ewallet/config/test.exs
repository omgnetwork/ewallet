use Mix.Config

config :ewallet,
  websocket_endpoints: [
    EWallet.TestEndpoint,
    EWalletAPI.V1.Endpoint,
    AdminAPI.V1.Endpoint
  ]
