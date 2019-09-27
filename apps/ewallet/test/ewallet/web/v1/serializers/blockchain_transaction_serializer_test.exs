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

defmodule EWallet.Web.V1.BlockchainTransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.BlockchainTransactionSerializer

  describe "serialize/1 for single blockchain_transaction" do
    test "serializes into correct V1 blockchain_transaction format" do
      blockchain_transaction = build(:blockchain_transaction)

      expected = %{
        object: "blockchain_transaction",
        hash: blockchain_transaction.hash,
        rootchain_identifier: blockchain_transaction.rootchain_identifier,
        childchain_identifier: blockchain_transaction.childchain_identifier,
        status: blockchain_transaction.status,
        block_number: blockchain_transaction.block_number,
        confirmed_at_block_number: blockchain_transaction.confirmed_at_block_number,
        gas_price: blockchain_transaction.gas_price,
        gas_limit: blockchain_transaction.gas_limit,
        error: blockchain_transaction.error,
        metadata: blockchain_transaction.metadata,
        created_at: blockchain_transaction.inserted_at,
        updated_at: blockchain_transaction.updated_at
      }

      assert BlockchainTransactionSerializer.serialize(blockchain_transaction) == expected
    end

    test "serializes to nil if the blockchain_transaction is not loaded" do
      assert BlockchainTransactionSerializer.serialize(%NotLoaded{}) == nil
    end
  end

  describe "serialize/1 for blockchain_transactions list" do
    test "serialize into list of V1 blockchain_transaction" do
      blockchain_transaction_1 = build(:blockchain_transaction)
      blockchain_transaction_2 = build(:blockchain_transaction)
      blockchain_transactions = [blockchain_transaction_1, blockchain_transaction_2]

      expected = [
        %{
          object: "blockchain_transaction",
          hash: blockchain_transaction_1.hash,
          rootchain_identifier: blockchain_transaction_1.rootchain_identifier,
          childchain_identifier: blockchain_transaction_1.childchain_identifier,
          status: blockchain_transaction_1.status,
          block_number: blockchain_transaction_1.block_number,
          confirmed_at_block_number: blockchain_transaction_1.confirmed_at_block_number,
          gas_price: blockchain_transaction_1.gas_price,
          gas_limit: blockchain_transaction_1.gas_limit,
          error: blockchain_transaction_1.error,
          metadata: blockchain_transaction_1.metadata,
          created_at: blockchain_transaction_1.inserted_at,
          updated_at: blockchain_transaction_1.updated_at
        },
        %{
          object: "blockchain_transaction",
          hash: blockchain_transaction_2.hash,
          rootchain_identifier: blockchain_transaction_2.rootchain_identifier,
          childchain_identifier: blockchain_transaction_2.childchain_identifier,
          status: blockchain_transaction_2.status,
          block_number: blockchain_transaction_2.block_number,
          confirmed_at_block_number: blockchain_transaction_2.confirmed_at_block_number,
          gas_price: blockchain_transaction_2.gas_price,
          gas_limit: blockchain_transaction_2.gas_limit,
          error: blockchain_transaction_2.error,
          metadata: blockchain_transaction_2.metadata,
          created_at: blockchain_transaction_2.inserted_at,
          updated_at: blockchain_transaction_2.updated_at
        }
      ]

      assert BlockchainTransactionSerializer.serialize(blockchain_transactions) == expected
    end
  end
end
