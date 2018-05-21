use Mix.Config

config :ewallet,
  websocket_endpoints: [
    EWalletAPI.V1.Endpoint
  ]

config :logger, level: :debug

unless IEx.started?() do
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
end
