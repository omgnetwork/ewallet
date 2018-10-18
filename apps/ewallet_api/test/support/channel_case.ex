defmodule EWalletAPI.ChannelCase do
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
  alias EWalletConfig.ConfigTest

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      alias Ecto.Adapters.SQL.Sandbox
      import EWalletDB.Factory

      # The default endpoint for testing
      @endpoint EWalletAPI.V1.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(EWalletConfig.Repo)
    :ok = Sandbox.checkout(EWalletDB.Repo)
    :ok = Sandbox.checkout(LocalLedgerDB.Repo)

    unless tags[:async] do
      Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
      Sandbox.mode(EWalletDB.Repo, {:shared, self()})
      Sandbox.mode(LocalLedgerDB.Repo, {:shared, self()})
    end

    ConfigTest.restart_config_genserver([:ewallet_db, :ewallet, :ewallet_api], %{
      "enable_standalone" => true,
      "base_url" => "http://localhost:4000",
      "email_adapter" => "test"
    })

    :ok
  end
end
