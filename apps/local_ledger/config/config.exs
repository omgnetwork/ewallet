use Mix.Config

# BALANCE_CACHING_STRATEGY
# since_beginning
# since_last_cached
config :local_ledger,
  ecto_repos: [],
  balance_caching_strategy: {:system, "BALANCE_CACHING_STRATEGY", "since_beginning"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
