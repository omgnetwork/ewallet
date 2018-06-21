defmodule AdminAPI.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate
  use Phoenix.ConnTest
  import Ecto.Query
  import EWalletDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWalletDB.{Repo, User, Account, Key}
  alias EWallet.{MintGate, TransactionGate}
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.Types.ExternalID

  # Attributes required by Phoenix.ConnTest
  @endpoint AdminAPI.Endpoint

  # Attributes for all calls
  # The expected response version
  @expected_version "1"
  # The expected response version
  @header_accept "application/vnd.omisego.v1+json"

  # Attributes for client calls
  @api_key_id UUID.generate()
  @api_key "test_api_key"

  # Attributes for provider calls
  @access_key "test_access_key"
  @secret_key "test_secret_key"

  # Attributes for user calls
  @admin_id ExternalID.generate("usr_")
  @username "test_username"
  @password "test_password"
  @user_email "email@example.com"
  @provider_user_id "test_provider_user_id"
  @auth_token "test_auth_token"

  @base_dir "admin/api/"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import AdminAPI.ConnCase
      import AdminAPI.Router.Helpers
      import EWalletDB.Factory

      # Reiterate all module attributes from `AdminAPI.ConnCase`
      @endpoint unquote(@endpoint)

      @expected_version unquote(@expected_version)
      @header_accept unquote(@header_accept)

      @access_key unquote(@access_key)
      @secret_key unquote(@secret_key)

      @api_key_id unquote(@api_key_id)
      @api_key unquote(@api_key)

      @admin_id unquote(@admin_id)
      @username unquote(@username)
      @password unquote(@password)
      @user_email unquote(@user_email)
      @provider_user_id unquote(@provider_user_id)
      @auth_token unquote(@auth_token)

      @base_dir unquote(@base_dir)
    end
  end

  setup do
    :ok = Sandbox.checkout(EWalletDB.Repo)
    :ok = Sandbox.checkout(LocalLedgerDB.Repo)

    # Insert account via `Account.insert/1` instead of the test factory to initialize wallets, etc.
    {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()

    # Insert necessary records for making authenticated calls.
    admin =
      insert(:user, %{
        id: @admin_id,
        email: @user_email,
        password_hash: Crypto.hash_password(@password)
      })

    # Insert user via `User.insert/1` to initialize wallets, etc.
    {:ok, _user} =
      :user
      |> params_for(%{username: @username, provider_user_id: @provider_user_id})
      |> User.insert()

    _auth_token =
      insert(:auth_token, %{
        user: admin,
        account: account,
        token: @auth_token,
        owner_app: "admin_api"
      })

    # Keys need to be inserted through `EWalletDB.Key.insert/1`
    # so that the secret key is hashed and usable by the tests.
    :key
    |> params_for(%{
      account: account,
      access_key: @access_key,
      secret_key: @secret_key
    })
    |> Key.insert()

    role = insert(:role, %{name: "admin"})
    _api_key = insert(:api_key, %{id: @api_key_id, key: @api_key, owner_app: "admin_api"})
    _membership = insert(:membership, %{user: admin, role: role, account: account})

    # Setup could return all the inserted credentials using ExUnit context
    # by returning {:ok, context_map}. But it would make the code
    # much less readable, i.e. `test "my test name", context do`,
    # and access using `context[:attribute]`.
    :ok
  end

  def stringify_keys(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {convert_key(key), stringify_keys(val)}
  end

  def stringify_keys(value), do: value
  def convert_key(key) when is_atom(key), do: Atom.to_string(key)
  def convert_key(key), do: key

  @doc """
  Returns the user that has just been created from the test setup.
  """
  def get_test_admin, do: User.get(@admin_id)
  def get_test_user, do: User.get_by_provider_user_id(@provider_user_id)

  @doc """
  Returns the last inserted record of the given schema.
  """
  def get_last_inserted(schema) do
    schema
    |> last(:inserted_at)
    |> Repo.one()
  end

  def mint!(token, amount \\ 1_000_000) do
    {:ok, mint, _transaction} =
      MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "description" => "Minting #{amount} #{token.symbol}",
        "metadata" => %{}
      })

    assert mint.confirmed == true
    mint
  end

  def set_initial_balance(%{
        address: address,
        token: token,
        amount: amount
      }) do
    account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(account)

    mint!(token, amount * 100)

    transfer!(
      master_wallet.address,
      address,
      token,
      amount * token.subunit_to_unit
    )
  end

  def transfer!(from, to, token, amount) do
    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => from,
        "to_address" => to,
        "token_id" => token.id,
        "amount" => amount,
        "metadata" => %{},
        "idempotency_token" => UUID.generate()
      })

    transaction
  end

  @doc """
  A helper function that generates a valid unauthenticated request
  with given path and data, and return the parsed JSON response.
  """
  @spec unauthenticated_request(String.t(), map(), keyword()) :: map() | no_return()
  def unauthenticated_request(path, data \\ %{}, opts \\ []) do
    {status, _opts} = Keyword.pop(opts, :status, :ok)

    build_conn()
    |> put_req_header("accept", @header_accept)
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  @doc """
  A helper function that generates a valid provider request
  with given path and data, and return the parsed JSON response.
  """
  def provider_request(path, data \\ %{}, status \\ :ok)
      when is_binary(path) and byte_size(path) > 0 do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGProvider", @access_key, @secret_key)
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  @doc """
  A helper function that generates an invalid user request (user-authenticated)
  with given path and data, and return the parsed JSON response.
  """
  @spec admin_user_request(String.t(), map(), keyword()) :: map() | no_return()
  def admin_user_request(path, data \\ %{}, opts \\ []) do
    {status, opts} = Keyword.pop(opts, :status, :ok)

    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", user_auth_header(opts))
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  defp user_auth_header(opts) do
    user_id = Keyword.get(opts, :user_id, @admin_id)
    auth_token = Keyword.get(opts, :auth_token, @auth_token)

    [user_id, auth_token]
  end

  @doc """
  Helper functions that puts an Authorization header to the connection.
  It can handle BasicAuth-like format, i.e. starts with auth type,
  followed by a space, then the base64 pair of credentials.
  """
  def put_auth_header(conn, type, access_key, secret_key) do
    put_auth_header(conn, type, Base.encode64(access_key <> ":" <> secret_key))
  end

  def put_auth_header(conn, type, content) when is_list(content) do
    serialized = content |> Enum.join(":") |> Base.encode64()
    put_auth_header(conn, type, serialized)
  end

  def put_auth_header(conn, type, content) when is_binary(content) do
    put_req_header(conn, "authorization", type <> " " <> content)
  end

  @doc """
  Checks the number of existing records for the given `schema`.
  It then populates more records to meet the given `num_required`.
  """
  def ensure_num_records(schema, num_required, attrs \\ %{}, count_field \\ :id) do
    num_remaining = num_required - Repo.aggregate(schema, :count, count_field)
    factory_name = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
  end
end
