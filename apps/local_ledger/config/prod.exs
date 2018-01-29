use Mix.Config

# Optional ENV: CACHE_BALANCES_FREQUENCY
# Daily at 2am: 0 2 * * *
# Every Friday at 5am: 0 5 * * 5
case System.get_env("CACHE_BALANCES_FREQUENCY") do
  nil -> :ok
  frequency ->
    config :local_ledger, LocalLedger.Scheduler,
      jobs: [{frequency, {LocalLedger.CachedBalance, :cache_all, []}}]
end
