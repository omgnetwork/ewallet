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

defmodule EWallet.DBCase do
  @moduledoc """
  A test case template for tests that need to connect to the database.
  """
  use ExUnit.CaseTemplate
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias Ecto.UUID
  alias Ecto.Adapters.SQL.Sandbox
  alias EWallet.{MintGate, TransactionGate}
  alias EWalletDB.{Account, Repo}
  alias EWalletConfig.ConfigTestHelper

  @temp_test_file_dir "private/temp_test_files"

  using do
    quote do
      import EWallet.DBCase
    end
  end

  setup tags do
    # Create the directory to store the temporary test files
    :ok = File.mkdir_p!(test_file_path())

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

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:ewallet_db, :ewallet],
      %{
        "enable_standalone" => false,
        "base_url" => "http://localhost:4000",
        "email_adapter" => "test"
      }
    )

    {:ok, _account} = :account |> params_for(parent: nil) |> Account.insert()

    %{config_pid: config_pid}
  end

  def ensure_num_records(schema, num_required, attrs \\ %{}, count_field \\ :id) do
    num_remaining = num_required - Repo.aggregate(schema, :count, count_field)
    factory_name = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
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

  def initialize_wallet(wallet, amount, token) do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)

    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => master_wallet.address,
        "to_address" => wallet.address,
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "metadata" => %{},
        "idempotency_token" => UUID.generate(),
        "originator" => %System{}
      })

    transaction
  end

  def test_file_path do
    :ewallet
    |> Application.get_env(:root)
    |> Path.join(@temp_test_file_dir)
  end

  def test_file_path(file_name) do
    Path.join(test_file_path(), file_name)
  end

  def is_url?(url) do
    String.starts_with?(url, "https://") || String.starts_with?(url, "http://")
  end
end
