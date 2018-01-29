use Mix.Config

config :local_ledger, LocalLedger.Scheduler,
  jobs: [{"0 2 * * *", {LocalLedger.CachedBalance, :cache_all, []}}]
