use Mix.Config

# Optional ENV: BALANCE_CACHING_FREQUENCY
# Daily at 2am: 0 2 * * *
# Every Friday at 5am: 0 5 * * 5
config :local_ledger, LocalLedger.Scheduler,
  global: true,
  jobs: {:apply, {LocalLedger.Config, :read_scheduler_config, []}}
