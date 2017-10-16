use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kubera_api, KuberaAPI.Endpoint,
  http: [port: 4001],
  server: false

# Uncomment this line to hide database requests when running tests
config :logger, level: :warn
