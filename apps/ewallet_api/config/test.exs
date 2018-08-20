use Mix.Config

# Enable features so they can be tested
config :ewallet_api, enable_standalone: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ewallet_api, EWalletAPI.Endpoint, server: false

config :ewallet_api, EWalletAPI.V1.Endpoint, server: false

# We do not do node discovery during test.
config :peerage,
  via: Peerage.Via.Self,
  log_results: false
