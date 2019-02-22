# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  alias EWalletConfig.ConfigTestHelper
  alias EWalletDB.{Account, Membership, GlobalRole, Key, Repo, User}
  alias Utils.{Types.ExternalID, Helpers.Crypto, Helpers.DateFormatter}
  alias ActivityLogger.System

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

      import ActivityLogger.ActivityLoggerTestHelper

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
    # Restarts `EWalletConfig.Config` so it does not hang on to a DB connection for too long.
    Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
    Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

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

    # Insert account via `Account.insert/1` instead of the test
    # factory to initialize wallets, etc.
    {:ok, account} = :account |> params_for() |> Account.insert()

    config_pid = start_config_server(account)

    # Insert necessary records for making authenticated calls.
    admin =
      insert(:admin, %{
        id: @admin_id,
        email: @user_email,
        password_hash: Crypto.hash_password(@password),
        global_role: GlobalRole.super_admin()
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
    {:ok, key} =
      :key
      |> params_for(%{
        access_key: @access_key,
        secret_key: @secret_key,
        global_role: GlobalRole.super_admin()
      })
      |> Key.insert()

    role = insert(:role, %{name: "admin"})

    {:ok, _} = Membership.assign(admin, account, role, %System{})
    {:ok, _} = Membership.assign(key, account, role, %System{})
    _api_key = insert(:api_key, %{id: @api_key_id, key: @api_key, owner_app: "admin_api"})

    # Setup could return all the inserted credentials using ExUnit context
    # by returning {:ok, context_map}. But it would make the code
    # much less readable, i.e. `test "my test name", context do`,
    # and access using `context[:attribute]`.
    %{config_pid: config_pid}
  end

  def start_config_server(account) do
    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:ewallet_db, :ewallet, :admin_api],
      %{
        "base_url" => "http://localhost:4000",
        "email_adapter" => "test",
        "sender_email" => "admin@example.com",
        "master_account" => account.uuid
      }
    )

    config_pid
  end

  def stringify_keys(%NaiveDateTime{} = value) do
    DateFormatter.to_iso8601(value)
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
  def get_test_key, do: Key.get_by(%{access_key: @access_key})

  @doc """
  Returns the last inserted record of the given schema.
  """
  def get_last_inserted(schema) do
    schema
    |> last(:inserted_at)
    |> Repo.one()
  end

  @spec set_admin_as_super_admin() :: {:ok, EWalletDB.User.t()}
  def set_admin_as_super_admin(admin_user \\ nil) do
    {:ok, _} =
      User.update(admin_user || get_test_admin(), %{
        global_role: "super_admin",
        originator: %System{}
      })
  end

  @spec add_admin_to_account(%Account{}, %User{} | %Key{}) :: {:ok, any()}
  def add_admin_to_account(account, admin_user \\ nil) do
    {:ok, _} = Membership.assign(admin_user || get_test_admin(), account, "admin", %System{})
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

    path
    |> provider_raw_request(data, opts)
    |> json_response(status)
  end

  def provider_raw_request(path, data \\ %{}, opts \\ []) do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGProvider", provider_auth_header(opts))
    |> post(@base_dir <> path, data)
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

    path
    |> admin_user_raw_request(data, opts)
    |> json_response(status)
  end

  def admin_user_raw_request(path, data \\ %{}, opts \\ []) do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGAdmin", user_auth_header(opts))
    |> post(@base_dir <> path, data)
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
  defmacro test_supports_match_any(endpoint, factory, field, opts \\ []) do
    quote do
      test_with_auths "supports match_any filtering" do
        endpoint = unquote(endpoint)
        factory = unquote(factory)
        field = unquote(field)
        opts = unquote(opts)
        field_name = Atom.to_string(field)

        set_admin_as_super_admin()

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

        response = request(endpoint, attrs)

        assert response["success"]

        records = response["data"]["data"]
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "value_2" end)
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "value_4" end)
        assert Enum.count(records) == 2
      end

      test_with_auths "handles unsupported match_any comparator" do
        endpoint = unquote(endpoint)
        field = unquote(field)
        field_name = Atom.to_string(field)

        attrs = %{
          "match_any" => [
            %{
              "field" => field_name,
              "comparator" => "starts_with",
              "value" => nil
            }
          ]
        }

        response = request(endpoint, attrs)

        refute response["success"]
        assert response["data"]["object"] == "error"
        assert response["data"]["code"] == "client:invalid_parameter"

        assert response["data"]["description"] ==
                 "Invalid parameter provided. " <>
                   "Querying for '#{field_name}' 'starts_with' 'nil' is not supported."
      end
    end
  end

  @doc """
  Tests that the specified endpoint supports 'match_all' filtering.
  """
  defmacro test_supports_match_all(endpoint, factory, field, opts \\ []) do
    quote do
      test_with_auths "supports match_all filtering" do
        endpoint = unquote(endpoint)
        factory = unquote(factory)
        field = unquote(field)
        opts = unquote(opts)
        field_name = Atom.to_string(field)

        set_admin_as_super_admin()

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

        response = request(endpoint, attrs)

        assert response["success"]

        records = response["data"]["data"]
        assert Enum.any?(records, fn r -> Map.get(r, field_name) == "this_should_match" end)
        assert Enum.count(records) == 1
      end

      test_with_auths "handles unsupported match_all comparator" do
        endpoint = unquote(endpoint)
        field = unquote(field)
        field_name = Atom.to_string(field)

        attrs = %{
          "match_all" => [
            %{
              "field" => field_name,
              "comparator" => "starts_with",
              "value" => nil
            }
          ]
        }

        response = request(endpoint, attrs)

        refute response["success"]
        assert response["data"]["object"] == "error"
        assert response["data"]["code"] == "client:invalid_parameter"

        assert response["data"]["description"] ==
                 "Invalid parameter provided. " <>
                   "Querying for '#{field_name}' 'starts_with' 'nil' is not supported."
      end
    end
  end

  @doc """
  Converts the given test block into 2 independent tests: one that makes a provider_auth request,
  and another that makes an admin_auth request.

  This function converts all `request/3` calls found in the code block into
  `provider_request/3` and `admin_user_request/3` automatically.

  For example:

  ```
  test_with_auths "request function is converted" do
    response = request("/account.all", %{})
  end
  ```

  Becomes:

  ```
  test "request function is converted with admin_auth" do
    response = admin_user_request("/account.all", %{})
  end

  test "request function is converted with provider_auth" do
    response = provider_request("/account.all", %{})
  end
  ```
  """
  defmacro test_with_auths(test_name, var \\ quote(do: _), do: test_block) do
    var = Macro.escape(var)

    provider_test_block =
      test_block
      |> Macro.prewalk(fn
        {:request, meta, args} -> {:provider_request, meta, args}
        {:raw_request, meta, args} -> {:provider_raw_request, meta, args}
        node -> node
      end)
      |> Macro.escape(unquote: true)

    admin_test_block =
      test_block
      |> Macro.prewalk(fn
        {:request, meta, args} -> {:admin_user_request, meta, args}
        {:raw_request, meta, args} -> {:admin_user_raw_request, meta, args}
        node -> node
      end)
      |> Macro.escape(unquote: true)

    quote bind_quoted: [
            var: var,
            test_name: test_name,
            provider_test_block: provider_test_block,
            admin_test_block: admin_test_block
          ] do
      admin_test_name = :"#{test_name} with admin_auth"
      provider_test_name = :"#{test_name} with provider_auth"

      {_, describe} = Module.get_attribute(__MODULE__, :ex_unit_describe)
      admin_func_name = :"#{describe} #{admin_test_name}"
      provider_func_name = :"#{describe} #{provider_test_name}"

      def unquote(admin_func_name)(unquote(var)), do: unquote(admin_test_block)
      def unquote(provider_func_name)(unquote(var)), do: unquote(provider_test_block)

      test admin_test_name, meta do
        unquote(admin_func_name)(meta)
      end

      # test provider_test_name, meta do
      #   unquote(provider_func_name)(meta)
      # end
    end
  end

  @doc """
  Make a request using `provider_request/3` or `admin_user_request/3`
  depending on the running context.

  This function can only be used within `test_with_auths/2`, and cannot
  be invoked directly.

  To make a request, use `provider_request/3` or `admin_user_request/3` instead.
  """
  def request(_, _, _) do
    raise UndefinedFunctionError
  end

  @doc """
  Make a request using `provider_raw_request/3` or `admin_user_raw_request/3`
  depending on the running context.

  This function can only be used within `test_with_auths/2`, and cannot
  be invoked directly.

  To make a request, use `provider_raw_request/3` or `admin_user_raw_request/3` instead.
  """
  def raw_request(_, _, _) do
    raise UndefinedFunctionError
  end
end
