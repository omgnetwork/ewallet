use Mix.Config

endpoints = []

endpoints =
  if Code.ensure_compiled?(EWalletAPI.V1.Endpoint),
    do: endpoints ++ [EWalletAPI.V1.Endpoint],
    else: endpoints

endpoints =
  if Code.ensure_compiled?(AdminAPI.V1.Endpoint),
    do: endpoints ++ [AdminAPI.V1.Endpoint],
    else: endpoints

config :ewallet,
  websocket_endpoints: endpoints

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
