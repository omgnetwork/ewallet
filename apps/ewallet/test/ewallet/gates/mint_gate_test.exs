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

defmodule EWallet.MintGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias Ecto.UUID
  alias EWallet.{BlockchainHelper, MintGate}
  alias EWalletDB.{BlockchainWallet, Token, TransactionState}
  alias ActivityLogger.System

  @big_number 100_000_000_000_000_000_000_000_000_000_000_000 - 1

  describe "insert_with_blockchain_transaction" do
    test "inserts a new mint for an existing erc20 token" do
      {:ok, omg} =
        :external_blockchain_token
        |> params_for(symbol: "OMG")
        |> Token.Blockchain.insert_with_blockchain_address()

      blockchain_transaction = insert(:blockchain_transaction_rootchain)

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      {res, mint, transaction} =
        MintGate.insert_with_blockchain_transaction(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => omg.id,
          "blockchain_transaction_uuid" => blockchain_transaction.uuid,
          "contract_address" => omg.blockchain_address,
          "hot_wallet_address" => hot_wallet.address,
          "amount" => 10_000 * omg.subunit_to_unit,
          "description" => "Minting 10_000 #{omg.symbol}",
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == false
      assert transaction.status == TransactionState.blockchain_submitted()
    end

    test "inserts a new mint for an existing erc20 token with big number" do
      {:ok, omg} =
        :external_blockchain_token
        |> params_for(symbol: "OMG")
        |> Token.Blockchain.insert_with_blockchain_address()

      blockchain_transaction = insert(:blockchain_transaction_rootchain)

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      {res, mint, transaction} =
        MintGate.insert_with_blockchain_transaction(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => omg.id,
          "blockchain_transaction_uuid" => blockchain_transaction.uuid,
          "contract_address" => omg.blockchain_address,
          "hot_wallet_address" => hot_wallet.address,
          "amount" => @big_number,
          "description" => "Minting 10_000 #{omg.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == false
      assert mint.amount == @big_number
      assert transaction.status == TransactionState.blockchain_submitted()
    end

    test "fails to insert a new mint for an existing erc20 token when the data is invalid" do
      {:ok, omg} =
        :external_blockchain_token
        |> params_for(symbol: "OMG")
        |> Token.Blockchain.insert_with_blockchain_address()

      blockchain_transaction = insert(:blockchain_transaction_rootchain)

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      {res, changeset} =
        MintGate.insert_with_blockchain_transaction(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => omg.id,
          "blockchain_transaction_uuid" => blockchain_transaction.uuid,
          "contract_address" => omg.blockchain_address,
          "hot_wallet_address" => hot_wallet.address,
          "amount" => nil,
          "description" => "description",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"can't be blank", [validation: :required]}
             ]
    end
  end

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 10_000 * btc.subunit_to_unit,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert transaction.status == TransactionState.confirmed()
    end

    test "inserts a new confirmed mint with big number" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => @big_number,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert mint.amount == @big_number
      assert transaction.status == TransactionState.confirmed()
    end

    test "fails to insert a new mint when the data is invalid" do
      {:ok, token} = Token.insert(params_for(:token))

      {res, changeset} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => token.id,
          "amount" => nil,
          "description" => "description",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"can't be blank", [validation: :required]}
             ]
    end
  end
end
