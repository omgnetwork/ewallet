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

defmodule EWallet.TransactionGate.ChildchainTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{
    BlockchainHelper,
    TransactionGate.Childchain,
    TransactionRegistry
  }

  alias EWalletDB.{BlockchainWallet, Transaction, TransactionState}
  alias Ecto.UUID
  alias ActivityLogger.System

  describe "deposit/2" do
    test "formats and forward attributes to the blockchain gate", meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "address" => hot_wallet.address,
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Childchain.deposit(admin, attrs)

      {:ok, contract_address} = BlockchainHelper.call(:get_childchain_contract_address)

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.deposit()
      assert transaction.blockchain_identifier == identifier
      assert transaction.from_blockchain_address == hot_wallet.address
      assert transaction.to_blockchain_address == contract_address

      {:ok, %{pid: pid}} = TransactionRegistry.lookup(transaction.uuid)

      {:ok, %{pid: blockchain_listener_pid}} =
        meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)

      # to update the transactions after the test is done.
      on_exit(fn ->
        :ok = GenServer.stop(pid)
        :ok = GenServer.stop(blockchain_listener_pid)
      end)
    end

    test "returns an error if the amount is not an integer" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "address" => hot_wallet.address,
        "token_id" => primary_blockchain_token.id,
        "amount" => "1",
        "originator" => %System{}
      }

      {res, code, error} = TransactionGate.Childchain.deposit(admin, attrs)
      assert res == :error
      assert code == :invalid_parameter
      assert error == "Invalid parameter provided. `amount` is required."
    end
  end
end
