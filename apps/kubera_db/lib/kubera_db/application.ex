defmodule KuberaDB.Application do
  @moduledoc """
  The KuberaDB Data Store

  Kebura's data store lives in this application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      supervisor(KuberaDB.Repo, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KuberaDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
