defmodule EWallet.DBCase do
  @moduledoc """
  A test case template for tests that need to connect to the DB.
  """
  import EWalletDB.Factory
  alias EWalletDB.Repo
  alias EWalletConfig.ConfigTestHelper

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWallet.DBCase
      import EWalletDB.Factory
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo
      alias EWalletDB.Account

      setup tags do
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(LocalLedgerDB.Repo)
        :ok = Sandbox.checkout(EWalletConfig.Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)

        unless tags[:async] do
          Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
          Sandbox.mode(EWalletDB.Repo, {:shared, self()})
          Sandbox.mode(LocalLedgerDB.Repo, {:shared, self()})
          Sandbox.mode(ActivityLogger.Repo, {:shared, self()})
        end

        pid =
          ConfigTestHelper.restart_config_genserver(
            self(),
            EWalletConfig.Repo,
            [:ewallet_db, :ewallet],
            %{
              "enable_standalone" => false,
              "base_url" => "http://localhost:4000",
              "email_adapter" => "test"
            }
          )

        %{config_pid: pid}
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
