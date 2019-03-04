use Mix.Config

config :local_ledger,
  ecto_repos: [],
  settings: [
    :balance_caching_strategy,
    :balance_caching_reset_frequency
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
