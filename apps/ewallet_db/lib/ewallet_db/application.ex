defmodule EWalletDB.Application do
  @moduledoc """
  The EWalletDB Data Store

  Kebura's data store lives in this application.
  """
  use Application
  alias EWalletConfig.Config
  alias EWalletDB.Setting

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_db)
    Config.load(:ewallet_db, :file_storage)

    # List all child processes to be supervised
    children = [
      supervisor(EWalletDB.Repo, [])
    ]

    children =
      case Setting.get_value("file_storage_adapter") do
        "gcs" -> children ++ [supervisor(Goth.Supervisor, [])]
        _ -> children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
