defmodule EWalletDB.Application do
  @moduledoc """
  The EWalletDB Data Store

  Kebura's data store lives in this application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      supervisor(EWalletDB.Repo, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
