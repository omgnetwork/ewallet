defmodule AdminAPI.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate, async: false
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletConfig.ConfigTestHelper

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      alias Ecto.Adapters.SQL.Sandbox
      import EWalletDB.Factory

      # The default endpoint for testing
      @endpoint AdminAPI.V1.Endpoint
    end
  end

  setup tags do
    # Restarts `EWalletConfig.Config` so it does not hang on to a DB connection for too long.
    Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
    Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

    :ok = Sandbox.checkout(EWalletDB.Repo)
    :ok = Sandbox.checkout(LocalLedgerDB.Repo)
    :ok = Sandbox.checkout(EWalletConfig.Repo)

    unless tags[:async] do
      Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
      Sandbox.mode(EWalletDB.Repo, {:shared, self()})
      Sandbox.mode(LocalLedgerDB.Repo, {:shared, self()})
    end

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:ewallet_db, :ewallet, :admin_api],
      %{
        "base_url" => "http://localhost:4000",
        "email_adapter" => "test",
        "sender_email" => "admin@example.com"
      }
    )

    %{config_pid: config_pid}
  end
end
