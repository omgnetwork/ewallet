use Mix.Config

# Configs for Bamboo emailing library
config :ewallet, EWallet.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: {:system, "SMTP_HOST"},
  port: {:system, "SMTP_PORT"},
  username: {:system, "SMTP_USER"},
  password: {:system, "SMTP_PASSWORD"}

config :ewallet, websocket_endpoints: [EWalletAPI.V1.Endpoint, AdminAPI.V1.Endpoint]

config :ewallet, EWallet.Scheduler,
  global: true,
  jobs: [
    expire_requests: [
      schedule: "* * * * *",
      task: {EWallet.TransactionRequestScheduler, :expire_all, []},
      run_strategy: {Quantum.RunStrategy.Random, :cluster}
    ],
    expire_consumptions: [
      schedule: "* * * * *",
      task: {EWallet.TransactionConsumptionScheduler, :expire_all, []},
      run_strategy: {Quantum.RunStrategy.Random, :cluster}
    ]
  ]
