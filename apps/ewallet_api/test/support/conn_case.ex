# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.ConnCase do
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
  import Ecto.Query
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWallet.{MintGate, TransactionGate}
  alias EWalletDB.{Account, Repo, User}
  alias EWalletConfig.ConfigTestHelper
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  # Attributes required by Phoenix.ConnTest
  @endpoint EWalletAPI.Endpoint

  # Attributes for all calls
  # The expected response version
  @expected_version "1"
  # The expected response version
  @header_accept "application/vnd.omisego.v1+json"

  # Attributes for client calls
  @api_key "test_api_key"
  @auth_token "test_auth_token"
  @username "test_username"
  @provider_user_id "test_provider_user_id"

  @base_dir "api/client"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import EWalletAPI.ConnCase
      import EWalletAPI.Router.Helpers
      import EWalletDB.Factory
      import ActivityLogger.ActivityLoggerTestHelper

      # Reiterate all module attributes from
      @endpoint EWalletAPI.Endpoint
      @expected_version unquote(@expected_version)
      @header_accept unquote(@header_accept)
      @api_key unquote(@api_key)
      @auth_token unquote(@auth_token)
      @username unquote(@username)
      @provider_user_id unquote(@provider_user_id)
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

    # Insert account via `Account.insert/1` instead of the test factory to initialize wallets, etc.
    {:ok, account} = :account |> params_for() |> Account.insert()

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:ewallet_db, :ewallet, :ewallet_api],
      %{
        "enable_standalone" => true,
        "base_url" => "http://localhost:4000",
        "email_adapter" => "test",
        "master_account" => account.id
      }
    )

    # Insert user via `User.insert/1` to initialize wallets, etc.
    {:ok, user} =
      :user
      |> params_for(%{username: @username, provider_user_id: @provider_user_id})
      |> User.insert()

    _api_key = insert(:api_key, %{key: @api_key})

    _auth_token =
      insert(:auth_token, %{
        user: user,
        account: account,
        token: @auth_token,
        owner_app: "ewallet_api"
      })

    # Setup could return all the inserted credentials using ExUnit context
    # by returning {:ok, context_map}. But it would make the code
    # much less readable, i.e. `test "my test name", context do`,
    # and access using `context[:attribute]`.
    %{config_pid: config_pid}
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

  def get_test_user do
    User.get_by_provider_user_id(@provider_user_id)
  end

  @doc """
  Returns the last inserted record of the given schema.
  """
  def get_last_inserted(schema) do
    schema
    |> last(:inserted_at)
    |> Repo.one()
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

  def mint!(token, amount \\ 1_000_000) do
    {:ok, mint, _transaction} =
      MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "description" => "Minting #{amount} #{token.symbol}",
        "metadata" => %{},
        "originator" => %System{}
      })

    assert mint.confirmed == true
    mint
  end

  def transfer!(from, to, token, amount) do
    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => from,
        "to_address" => to,
        "token_id" => token.id,
        "amount" => amount,
        "metadata" => %{},
        "idempotency_token" => UUID.generate(),
        "originator" => %System{}
      })

    transaction
  end

  @doc """
  A helper function that generates a valid public request
  with given path and data, and return the parsed JSON response.
  """
  def public_request(path, data \\ %{}, status \\ :ok)
      when is_binary(path) and byte_size(path) > 0 do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  @doc """
  A helper function that generates a valid client request
  with given path and data, and return the parsed JSON response.
  """
  def client_request(path, data \\ %{}, status \\ :ok)
      when is_binary(path) and byte_size(path) > 0 do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> put_auth_header("OMGClient", @api_key, @auth_token)
    |> post(@base_dir <> path, data)
    |> json_response(status)
  end

  @doc """
  Helper functions that puts an Authorization header to the connection.
  It can handle BasicAuth-like format, i.e. starts with auth type,
  followed by a space, then the base64 pair of credentials.
  """
  def put_auth_header(conn, type, access_key, secret_key) do
    put_auth_header(conn, type, Base.encode64(access_key <> ":" <> secret_key))
  end

  def put_auth_header(conn, type, content) do
    put_req_header(conn, "authorization", type <> " " <> content)
  end

  @doc """
  Sets the new config value, runs the given function,
  then sets the original value back.
  """
  def run_with(key, value, fun) do
    original = Application.get_env(:ewallet_api, key)
    :ok = Application.put_env(:ewallet_api, key, value)
    returned_value = fun.()
    :ok = Application.put_env(:ewallet_api, key, original)
    returned_value
  end
end
