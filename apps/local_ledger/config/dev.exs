use Mix.Config

config :local_ledger, LocalLedger.Scheduler,
  global: true,
  jobs: [
    {"0 2 * * *", {LocalLedger.CachedBalance, :cache_all, []}}
  ]
