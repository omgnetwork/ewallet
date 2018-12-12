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
  use Phoenix.ChannelTest
  import EWalletDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletConfig.{ConfigTestHelper, Helpers.Crypto, Types.ExternalID}
  alias EWalletDB.{Key, Account, User}

  # Attributes for provider calls
  @access_key "test_access_key"
  @secret_key "test_secret_key"

  @endpoint AdminAPI.V1.Endpoint

  # Attributes for user calls
  @admin_id ExternalID.generate("usr_")
  @password "test_password"
  @user_email "email@example.com"

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      alias Ecto.Adapters.SQL.Sandbox
      import EWalletDB.Factory
      import AdminAPI.ChannelCase

      # The default endpoint for testing
      @endpoint AdminAPI.V1.Endpoint

      @access_key unquote(@access_key)
      @secret_key unquote(@secret_key)

      @admin_id unquote(@admin_id)
      @password unquote(@password)
      @user_email unquote(@user_email)
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

    {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()

    admin =
      insert(:admin, %{
        id: @admin_id,
        email: @user_email,
        password_hash: Crypto.hash_password(@password)
      })

    role = insert(:role, %{name: "admin"})
    _membership = insert(:membership, %{user: admin, role: role, account: account})

    :key
    |> params_for(%{
      account: account,
      access_key: @access_key,
      secret_key: @secret_key
    })
    |> Key.insert()

    %{config_pid: config_pid}
  end

  def admin_auth_socket(admin_id \\ @admin_id) do
    socket("test", %{auth: %{authenticated: true, admin_user: User.get(admin_id)}})
  end

  def key_auth_socket(access_key \\ @access_key) do
    socket("test", %{
      auth: %{authenticated: true, key: Key.get_by(%{access_key: access_key}, preload: :account)}
    })
  end

  def test_with_auths(func, admin_id \\ @admin_id, access_key \\ @access_key) do
    Enum.each([admin_auth_socket(admin_id), key_auth_socket(access_key)], func)
  end

  def assert_success({res, _, socket}, topic) do
    assert res == :ok
    assert socket.topic == topic
  end

  def assert_failure({res, code}, error) do
    assert res == :error
    assert code == error
  end
end
