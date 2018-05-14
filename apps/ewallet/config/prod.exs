use Mix.Config

config :ewallet,
  websocket_endpoints: [
    EWalletAPI.V1.Endpoint
  ]

config :ewallet, EWallet.Scheduler,
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
