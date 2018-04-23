use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/ewallet_dev"

key = "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"

config :cloak, Salty.SecretBox.Cloak,
  tag: "SBX",
  default: true,
  keys: [%{tag: <<1>>, key: key, default: true}]

config :ewallet_db, EWalletDB.Scheduler,
  global: true,
  jobs: [
    expire_requests: [
      schedule: "* * * * *",
      task: {EWalletDB.TransactionRequest, :expire_all, []},
      run_strategy: {Quantum.RunStrategy.Random, :cluster}
    ],
    expire_consumptions: [
      schedule: "* * * * *",
      task: {EWalletDB.TransactionConsumption, :expire_all, []},
      run_strategy: {Quantum.RunStrategy.Random, :cluster}
    ]
  ]
