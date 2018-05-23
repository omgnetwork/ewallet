defmodule EWallet.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      worker(EWallet.Scheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWallet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
