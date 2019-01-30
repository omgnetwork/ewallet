use Mix.Config

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
      ],
      expire_forget_password_requests: [
        schedule: "* * * * *",
        task: {EWallet.ForgetPasswordRequestScheduler, :expire_all, []},
        run_strategy: {Quantum.RunStrategy.Random, :cluster}
      ]
    ]
end
