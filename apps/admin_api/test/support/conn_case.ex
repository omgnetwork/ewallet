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
  alias EWalletDB.{Repo, User, Account}
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

  # Attributes for user calls
  @user_id ExternalID.generate("usr_")
  @username "test_username"
  @password "test_password"
  @user_email "email@example.com"
  @provider_user_id "test_provider_user_id"
  @auth_token "test_auth_token"
  @include_client_auth true

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

      @api_key_id unquote(@api_key_id)
      @api_key unquote(@api_key)

      @user_id unquote(@user_id)
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

    # Insert necessary records for making authenticated calls.
    user =
      insert(:user, %{
        id: @user_id,
        username: @username,
        password_hash: Crypto.hash_password(@password),
        email: @user_email,
        provider_user_id: @provider_user_id
      })

    {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()
    role = insert(:role, %{name: "admin"})
    _api_key = insert(:api_key, %{id: @api_key_id, key: @api_key, owner_app: "admin_api"})
    _membership = insert(:membership, %{user: user, role: role, account: account})

    _auth_token =
      insert(:auth_token, %{
        user: user,
        account: account,
        token: @auth_token,
        owner_app: "admin_api"
      })

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
  def get_test_user, do: User.get(@user_id)

  @doc """
  Returns the last inserted record of the given schema.
  """
  def get_last_inserted(schema) do
    schema
    |> last(:inserted_at)
    |> Repo.one()
  end

  @doc """
  A helper function that generates a valid client request (client-authenticated)
  with given path and data, and return the parsed JSON response.
  """
  @spec client_request(String.t(), map(), keyword()) :: map() | no_return()
  def client_request(path, data \\ %{}, opts \\ []) do
    {status, opts} = Keyword.pop(opts, :status, :ok)

    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", client_auth_header(opts))
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  defp client_auth_header(opts) do
    api_key_id = Keyword.get(opts, :api_key_id, @api_key_id)
    api_key = Keyword.get(opts, :api_key, @api_key)

    [api_key_id, api_key]
  end

  @doc """
  A helper function that generates an invalid user request (user-authenticated)
  with given path and data, and return the parsed JSON response.
  """
  @spec user_request(String.t(), map(), keyword()) :: map() | no_return()
  def user_request(path, data \\ %{}, opts \\ []) do
    {status, opts} = Keyword.pop(opts, :status, :ok)

    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", user_auth_header(opts))
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  defp user_auth_header(opts) do
    api_key_id = Keyword.get(opts, :api_key_id, @api_key_id)
    api_key = Keyword.get(opts, :api_key, @api_key)
    user_id = Keyword.get(opts, :user_id, @user_id)
    auth_token = Keyword.get(opts, :auth_token, @auth_token)

    case Keyword.get(opts, :include_client_auth, @include_client_auth) do
      true ->
        [api_key_id, api_key, user_id, auth_token]

      false ->
        [user_id, auth_token]
    end
  end

  @doc """
  Helper functions that puts an Authorization header to the connection.
  It can handle BasicAuth-like format, i.e. starts with auth type,
  followed by a space, then the base64 pair of credentials.
  """
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
