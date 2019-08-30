ExUnit.start()
DeferredConfig.populate(:eth_elixir_omg_adapter)

children = [
  {Plug.Cowboy, scheme: :http, plug: EthElixirOmgAdapter.MockServer, options: [port: 8081]}
]

opts = [strategy: :one_for_one, name: EthElixirOmgAdapter.Supervisor]
{:ok, _pid} = Supervisor.start_link(children, opts)
