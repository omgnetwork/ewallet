use Mix.Config

# config :ethereumex, url: "http://localhost:8545", client_type: :http
config :ethereumex,
  url: {:system, "JSON_RPC_GETH_NODE_URL", "http://localhost:8545"},
  client_type: :http
