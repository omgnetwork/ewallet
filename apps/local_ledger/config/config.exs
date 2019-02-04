use Mix.Config

config :local_ledger,
  namespace: LocalLedger,
  ecto_repos: [],
  settings: [
    :balance_caching_strategy,
    :balance_caching_frequency
  ],
  scheduler: LocalLedger.Scheduler

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
