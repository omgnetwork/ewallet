defmodule EWallet.DBCase do
  @moduledoc """
  A test case template for tests that need to connect to the DB.
  """
  import EWalletDB.Factory
  alias EWalletDB.Repo

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWallet.DBCase
      import EWalletDB.Factory
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletConfig.Config
      alias EWalletDB.Repo

      setup tags do
        :ok = Sandbox.checkout(EWalletConfig.Repo)
        :ok = Sandbox.checkout(EWalletDB.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
        end

        :ok = Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
        {:ok, _} = Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

        settings = Application.get_env(:ewallet, :settings)
        Config.register_and_load(:ewallet, settings)

        Config.insert_all_defaults(%{
          "enable_standalone" => false,
          "base_url" => "http://localhost:4000",
          "email_adapter" => "test"
        })

        :ok
      end
    end
  end

  def ensure_num_records(schema, num_required, attrs \\ %{}, count_field \\ :id) do
    num_remaining = num_required - Repo.aggregate(schema, :count, count_field)
    factory_name = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
  end
end
