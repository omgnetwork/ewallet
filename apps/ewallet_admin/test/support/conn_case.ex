defmodule EWalletAdmin.ConnCase do
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
  import EWalletDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.{Repo, User}

  # Attributes required by Phoenix.ConnTest
  @endpoint EWalletAdmin.Endpoint

  # Attributes for all calls
  @expected_version "1" # The expected response version
  @header_accept "application/vnd.omisego.v1+json" # The expected response version

  # Attributes for client calls
  @api_key_id UUID.generate()
  @api_key "test_api_key"

  # Attributes for user calls
  @user_id UUID.generate()
  @username "test_username"
  @password "test_password"
  @user_email "email@example.com"
  @provider_user_id "test_provider_user_id"
  @auth_token "test_auth_token"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import EWalletAdmin.ConnCase
      import EWalletAdmin.Router.Helpers
      import EWalletDB.Factory

      # Reiterate all module attributes from `EWalletAdmin.ConnCase`
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
    end
  end

  setup do
    :ok = Sandbox.checkout(Repo)

    # Insert necessary records for making authenticated calls.
    user = insert(:user, %{
      id: @user_id,
      username: @username,
      password_hash: Crypto.hash_password(@password),
      email: @user_email,
      provider_user_id: @provider_user_id
    })
    _api_key    = insert(:api_key, %{id: @api_key_id, key: @api_key, owner_app: "ewallet_admin"})
    _auth_token = insert(:auth_token, %{user: user, token: @auth_token, owner_app: "ewallet_admin"})

    # Setup could return all the inserted credentials using ExUnit context
    # by returning {:ok, context_map}. But it would make the code
    # much less readable, i.e. `test "my test name", context do`,
    # and access using `context[:attribute]`.
    :ok
  end

  @doc """
  Returns the user that has just been created from the test setup.
  """
  def get_test_user, do: User.get(@user_id)

  @doc """
  A helper function that generates a valid client request (client-authenticated)
  with given path and data, and return the parsed JSON response.
  """
  def client_request(path, data \\ %{}, status \\ :ok) when is_binary(path) and byte_size(path) > 0 do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", [@api_key_id, @api_key])
    |> post(path, data)
    |> json_response(status)
  end

  @doc """
  A helper function that generates a valid user request (user-authenticated)
  with given path and data, and return the parsed JSON response.
  """
  def user_request(path, data \\ %{}, status \\ :ok) when is_binary(path) and byte_size(path) > 0 do
    # Make the authenticated request after login
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", [@api_key_id, @api_key, @user_id, @auth_token])
    |> post(path, data)
    |> json_response(status)
  end

  @doc """
  Helper functions that puts an Authorization header to the connection.
  It can handle BasicAuth-like format, i.e. starts with auth type,
  followed by a space, then the base64 pair of credentials.
  """
  def put_auth_header(conn, type, content) when is_list(content) do
    serialized = content |> Enum.join(":") |> Base.encode64
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
    factory_name  = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
  end
end
