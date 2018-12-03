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
  alias EWallet.{MintGate, TransactionGate}
  alias EWallet.Web.Date
  alias EWalletConfig.ConfigTestHelper
  alias EWalletDB.{Account, Key, Repo, User}
  alias ActivityLogger.System
  alias Utils.{Types.ExternalID, Helpers.Crypto}

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

  @base_dir "api/admin/"

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
        [:ewallet_db, :ewallet, :admin_api],
        %{
          "base_url" => "http://localhost:4000",
          "email_adapter" => "test",
          "sender_email" => "admin@example.com"
        }
      )

    # Insert account via `Account.insert/1` instead of the test factory to initialize wallets, etc.
    {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()

    # Insert necessary records for making authenticated calls.
    admin =
      insert(:admin, %{
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
    %{config_pid: pid}
  end

  def stringify_keys(%NaiveDateTime{} = value) do
    Date.to_iso8601(value)
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

  def mint!(token, amount \\ 1_000_000, originator \\ %System{}) do
    {:ok, mint, _transaction} =
      MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "description" => "Minting #{amount} #{token.symbol}",
        "metadata" => %{},
        "originator" => originator
      })

    assert mint.confirmed == true
    mint
  end

  def set_initial_balance(
        %{
          address: address,
          token: token,
          amount: amount
        },
        mint \\ true
      ) do
    account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(account)

    if mint do
      mint!(token, amount * 100)
    end

    transfer!(
      master_wallet.address,
      address,
      token,
      amount * token.subunit_to_unit
    )
  end

  def transfer!(from, to, token, amount, originator \\ %System{}) do
    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => from,
        "to_address" => to,
        "token_id" => token.id,
        "amount" => amount,
        "metadata" => %{},
        "idempotency_token" => UUID.generate(),
        "originator" => originator
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
  def provider_request(path, data \\ %{}, opts \\ [])
      when is_binary(path) and byte_size(path) > 0 do
    {status, _opts} = Keyword.pop(opts, :status, :ok)

    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGProvider", provider_auth_header(opts))
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  defp provider_auth_header(opts) do
    access_key = Keyword.get(opts, :access_key, @access_key)
    secret_key = Keyword.get(opts, :secret_key, Base.url_encode64(@secret_key))

    [access_key, secret_key]
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

  @doc """
  Tests that the specified endpoint supports 'match_any' filtering.
  """
  defmacro test_supports_match_any(endpoint, auth_type, factory, field, opts \\ []) do
    quote do
      test "supports match_any filtering" do
        endpoint = unquote(endpoint)
        auth_type = unquote(auth_type)
        factory = unquote(factory)
        field = unquote(field)
        opts = unquote(opts)
        field_name = Atom.to_string(field)

        factory_attrs = Keyword.get(opts, :factory_attrs, %{})

        _ = insert(factory, Map.merge(%{field => "value_1"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "value_2"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "value_3"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "value_4"}, factory_attrs))

        attrs = %{
          "match_any" => [
            %{
              "field" => field_name,
              "comparator" => "eq",
              "value" => "value_2"
            },
            %{
              "field" => field_name,
              "comparator" => "eq",
              "value" => "value_4"
            }
          ]
        }

        response =
          case auth_type do
            :admin_auth -> admin_user_request(endpoint, attrs)
            :provider_auth -> provider_request(endpoint, attrs)
          end

        assert response["success"]

        records = response["data"]["data"]
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "value_2" end)
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "value_4" end)
        assert Enum.count(records) == 2
      end
    end
  end

  @doc """
  Tests that the specified endpoint supports 'match_all' filtering.
  """
  defmacro test_supports_match_all(endpoint, auth_type, factory, field, opts \\ []) do
    quote do
      test "supports match_all filtering" do
        endpoint = unquote(endpoint)
        auth_type = unquote(auth_type)
        factory = unquote(factory)
        field = unquote(field)
        opts = unquote(opts)
        field_name = Atom.to_string(field)

        factory_attrs = Keyword.get(opts, :factory_attrs, %{})

        _ = insert(factory, Map.merge(%{field => "this_should_almost_match"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "this_should_match"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "should_not_match"}, factory_attrs))
        _ = insert(factory, Map.merge(%{field => "also_should_not_match"}, factory_attrs))

        attrs = %{
          "match_all" => [
            %{
              "field" => field_name,
              "comparator" => "starts_with",
              "value" => "this_should"
            },
            %{
              "field" => field_name,
              "comparator" => "contains",
              "value" => "should_match"
            }
          ]
        }

        response =
          case auth_type do
            :admin_auth -> admin_user_request(endpoint, attrs)
            :provider_auth -> provider_request(endpoint, attrs)
          end

        assert response["success"]

        records = response["data"]["data"]
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "this_should_match" end)
        assert Enum.count(records) == 1
      end
    end
  end
end
