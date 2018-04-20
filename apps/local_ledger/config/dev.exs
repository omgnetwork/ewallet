use Mix.Config

config :local_ledger, LocalLedger.Scheduler,
  global: true,
  jobs: [
    cache_all_balances: [
      schedule: "0 2 * * *",
      task: {LocalLedger.CachedBalance, :cache_all, []},
      run_strategy: {Quantum.RunStrategy.Random, :cluster} 
    ]
  ]
