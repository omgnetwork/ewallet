defmodule LocalLedgerDB.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:local_ledger_db)

    # List all child processes to be supervised
    children = [
      supervisor(LocalLedgerDB.Repo, [])
      # Starts a worker by calling: LocalLedgerDB.Worker.start_link(arg)
      # {LocalLedgerDB.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LocalLedgerDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
