use Mix.Config

config :local_ledger, LocalLedger.Scheduler,
  global: true,
  jobs: {:apply, {LocalLedger.Config, :read_scheduler_config, []}}
