defmodule EWalletDB.Application do
  @moduledoc """
  The EWalletDB Data Store

  Kebura's data store lives in this application.
  """
  use Application
  alias EWalletDB.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_db)
    Config.configure_file_storage()

    # List all child processes to be supervised
    children = [
      supervisor(EWalletDB.Repo, [])
    ]

    children =
      case System.get_env("FILE_STORAGE_ADAPTER") do
        "gcs" -> children ++ [supervisor(Goth.Supervisor, [])]
        _ -> children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
