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

defmodule EWallet.BlockchainTransactionGateTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{
    BlockchainHelper,
    BalanceFetcher,
    BlockchainDepositWalletGate,
    BlockchainTransactionGate,
    TransactionRegistry
  }

  alias EWalletDB.{Account, BlockchainWallet, Transaction, TransactionState}
  alias ActivityLogger.System
  alias Utils.Helpers.Crypto
  alias Ecto.UUID

  describe "create/2" do
    test "submits a transaction to the blockchain subapp (internal to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      mint!(primary_blockchain_token)

      {:ok, %{balances: [main_balance]}} = BalanceFetcher.all(%{"wallet" => master_wallet})
      assert main_balance[:amount] == 100_000_000

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => master_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create(admin, attrs, {false, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_identifier == identifier
      assert transaction.confirmations_count == nil

      {:ok, res} = TransactionRegistry.lookup(transaction.uuid)
      assert %{tracker: EWallet.TransactionTracker, pid: pid} = res

      {:ok, res} = meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)
      assert %{listener: _, pid: blockchain_listener_pid} = res

      ref = Process.monitor(blockchain_listener_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert %{confirmations_count: count, status: "confirmed"} = transaction
          assert count > 10

          {:ok, %{balances: [main_balance]}} = BalanceFetcher.all(%{"wallet" => master_wallet})
          assert main_balance[:amount] == 99_999_999
      end
    end

    test "submits a transaction to the blockchain subapp (hot wallet to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create(admin, attrs, {true, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_identifier == identifier
      assert transaction.confirmations_count == nil

      {:ok, res} = TransactionRegistry.lookup(transaction.uuid)
      assert %{tracker: EWallet.TransactionTracker, pid: pid} = res

      {:ok, res} = meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)
      assert %{listener: _, pid: blockchain_listener_pid} = res

      ref = Process.monitor(blockchain_listener_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert %{confirmations_count: 13, status: "confirmed"} = transaction
      end
    end

    test "returns an error when trying to exchange" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "from_token_id" => primary_blockchain_token.id,
        "to_token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :blockchain_exchange_not_allowed} ==
               BlockchainTransactionGate.create(admin, attrs, {true, true})
    end

    test "returns an error when amounts are not valid" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "from_amount" => 1,
        "to_amount" => 2,
        "originator" => %System{}
      }

      assert BlockchainTransactionGate.create(admin, attrs, {true, true}) ==
               {
                 :error,
                 :invalid_parameter,
                 "Invalid parameter provided. `from_amount` and `to_amount` must be equal." <>
                   " Given: 1 and 2 respectively."
               }
    end

    test "returns an error when the hot wallet doesn't have enough funds" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 125,
        "originator" => %System{}
      }

      assert {:error, :insufficient_funds_in_hot_wallet} ==
               BlockchainTransactionGate.create(admin, attrs, {true, true})
    end

    test "returns an error if the token is not a blockchain token" do
      admin = insert(:admin, global_role: "super_admin")
      token = insert(:token)

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :token_not_blockchain_enabled} ==
               BlockchainTransactionGate.create(admin, attrs, {true, true})
    end
  end

  describe "create_from_tracker/2" do
    test "creates the blockchain transaction and tracks it" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)
      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        idempotency_token: tx_hash,
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.pending(),
        type: Transaction.external(),
        blockchain_tx_hash: tx_hash,
        blockchain_identifier: identifier,
        confirmations_count: 0,
        blk_number: 1,
        payload: %{},
        blockchain_metadata: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: nil,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: hot_wallet.address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create_from_tracker(attrs)

      {:ok, %{pid: pid}} = TransactionRegistry.lookup(transaction.uuid)
      assert is_pid(pid)

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert transaction.status == "confirmed"
      end
    end

    test "creates the local transaction and starts tracking the blockchain transaction" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        idempotency_token: tx_hash,
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.pending(),
        type: Transaction.external(),
        blockchain_tx_hash: tx_hash,
        blockchain_identifier: identifier,
        confirmations_count: 0,
        blk_number: 1,
        payload: %{},
        blockchain_metadata: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: wallet.address,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: hd(wallet.blockchain_deposit_wallets).address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create_from_tracker(attrs)

      {:ok, %{pid: pid}} = TransactionRegistry.lookup(transaction.uuid)
      assert is_pid(pid)

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert transaction.status == "confirmed"
          # Check balance
          {:ok, %{balances: [balance]}} = BalanceFetcher.all(%{"wallet" => wallet})
          assert balance[:amount] == 1
          assert balance[:token].uuid == token.uuid
      end
    end

    test "creates the local transaction and confirms it right away when enough confirmations" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        idempotency_token: tx_hash,
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.pending(),
        type: Transaction.external(),
        blockchain_tx_hash: tx_hash,
        blockchain_identifier: identifier,
        confirmations_count: 11,
        blk_number: 1,
        payload: %{},
        blockchain_metadata: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: wallet.address,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: hd(wallet.blockchain_deposit_wallets).address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create_from_tracker(attrs)

      # We can't find the listener because there shouldn't be one
      assert TransactionRegistry.lookup(transaction.uuid) == {:error, :not_found}

      transaction = Transaction.get(transaction.id)
      assert transaction.status == "confirmed"
      # Check balance
      {:ok, %{balances: [balance]}} = BalanceFetcher.all(%{"wallet" => wallet})
      assert balance[:amount] == 1
      assert balance[:token].uuid == token.uuid
    end
  end

  describe "get_or_insert/1" do
    test "returns a newly inserted local transaction if the idempotency_token is new" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        "idempotency_token" => tx_hash,
        "from_amount" => 1,
        "to_amount" => 1,
        "status" => TransactionState.pending(),
        "type" => Transaction.external(),
        "blockchain_tx_hash" => tx_hash,
        "blockchain_identifier" => identifier,
        "confirmations_count" => 0,
        "blk_number" => 1,
        "payload" => %{},
        "blockchain_metadata" => %{},
        "from_token_uuid" => token.uuid,
        "to_token_uuid" => token.uuid,
        "to" => wallet.address,
        "from" => nil,
        "from_blockchain_address" => Crypto.fake_eth_address(),
        "to_blockchain_address" => hd(wallet.blockchain_deposit_wallets).address,
        "from_account" => nil,
        "to_account" => nil,
        "from_user" => nil,
        "to_user" => nil,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.get_or_insert(attrs)
      assert transaction.idempotency_token == tx_hash
    end

    test "returns the existing local transaction if the idempotency_token already exists" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        "idempotency_token" => tx_hash,
        "from_amount" => 1,
        "to_amount" => 1,
        "status" => TransactionState.pending(),
        "type" => Transaction.external(),
        "blockchain_tx_hash" => tx_hash,
        "blockchain_identifier" => identifier,
        "confirmations_count" => 0,
        "blk_number" => 1,
        "payload" => %{},
        "blockchain_metadata" => %{},
        "from_token_uuid" => token.uuid,
        "to_token_uuid" => token.uuid,
        "to" => wallet.address,
        "from" => nil,
        "from_blockchain_address" => Crypto.fake_eth_address(),
        "to_blockchain_address" => hd(wallet.blockchain_deposit_wallets).address,
        "from_account" => nil,
        "to_account" => nil,
        "from_user" => nil,
        "to_user" => nil,
        "originator" => %System{}
      }

      {:ok, transaction_1} = BlockchainTransactionGate.get_or_insert(attrs)
      {:ok, transaction_2} = BlockchainTransactionGate.get_or_insert(attrs)

      assert transaction_1.idempotency_token == tx_hash
      assert transaction_1.idempotency_token == transaction_2.idempotency_token
    end

    test "returns :idempotency_token if the idempotency_token is not given" do
      assert BlockchainTransactionGate.get_or_insert(%{}) ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `idempotency_token` is required."}
    end
  end

  describe "blockchain_addresses?/1" do
    test "returns a list of booleans indicating whether each given address is a blockchain address" do
      assert BlockchainTransactionGate.blockchain_addresses?([
               "abc",
               "0x",
               Crypto.fake_eth_address()
             ]) == [
               false,
               false,
               true
             ]
    end
  end

  describe "handle_local_insert/1" do
    test "transitions the transaction to confirmed if transaction.to is nil" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)
      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        idempotency_token: tx_hash,
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.blockchain_confirmed(),
        type: Transaction.external(),
        blockchain_tx_hash: tx_hash,
        blockchain_identifier: identifier,
        confirmations_count: 0,
        blk_number: 1,
        payload: %{},
        blockchain_metadata: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: nil,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: hot_wallet.address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} = Transaction.insert(attrs)
      assert transaction.status == TransactionState.blockchain_confirmed()

      {:ok, transaction} = BlockchainTransactionGate.handle_local_insert(transaction)
      assert transaction.status == TransactionState.confirmed()
    end

    test "processes the transaction with BlockchainLocalTransactionGate if transaction.to is not nil" do
      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        idempotency_token: tx_hash,
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.blockchain_confirmed(),
        type: Transaction.external(),
        blockchain_tx_hash: tx_hash,
        blockchain_identifier: identifier,
        confirmations_count: 11,
        blk_number: 1,
        payload: %{},
        blockchain_metadata: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: wallet.address,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: hd(wallet.blockchain_deposit_wallets).address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} = Transaction.insert(attrs)
      assert transaction.status == TransactionState.blockchain_confirmed()

      {:ok, transaction} = BlockchainTransactionGate.handle_local_insert(transaction)
      assert transaction.status == TransactionState.confirmed()
    end
  end
end
