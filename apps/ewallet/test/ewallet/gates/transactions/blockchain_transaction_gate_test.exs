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

defmodule EWallet.TransactionGate.BlockchainTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{
    BlockchainHelper,
    BalanceFetcher,
    TransactionGate,
    BlockchainDepositWalletGate,
    BlockchainTransactionTracker
  }

  alias EWalletDB.{
    Account,
    BlockchainState,
    BlockchainTransactionState,
    BlockchainWallet,
    Transaction,
    TransactionState
  }

  alias ActivityLogger.System
  alias Utils.Helpers.Crypto
  alias Ecto.UUID

  describe "create/2" do
    test "submits a transaction to the blockchain subapp (internal to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      identifier = BlockchainHelper.rootchain_identifier()
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
        "rootchain_identifier" => identifier,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Blockchain.create(admin, attrs, {false, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_transaction.rootchain_identifier == identifier
      assert transaction.blockchain_transaction.block_number == nil

      # Fast forward the blockchain manually to have the transaction confirmed.
      BlockchainState.update(identifier, 20)

      {:ok, tracker_pid} =
        BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)

      assert Process.alive?(tracker_pid)

      {:ok, listener} = meta[:adapter].lookup_listener(transaction.blockchain_transaction.hash)
      assert %{listener: _, pid: blockchain_listener_pid} = listener

      ref = Process.monitor(tracker_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id, preload: :blockchain_transaction)
          assert transaction.status == TransactionState.confirmed()
          assert transaction.blockchain_transaction.confirmed_at_block_number == 20

          {:ok, %{balances: [main_balance]}} = BalanceFetcher.all(%{"wallet" => master_wallet})
          assert main_balance[:amount] == 99_999_999
      end
    end

    test "submits a transaction to the blockchain subapp (hot wallet to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => identifier,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Blockchain.create(admin, attrs, {true, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_transaction.rootchain_identifier == identifier
      assert transaction.blockchain_transaction.block_number == nil

      # Fast forward the blockchain manually to have the transaction confirmed.
      BlockchainState.update(identifier, 20)

      {:ok, tracker_pid} =
        BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)

      assert Process.alive?(tracker_pid)

      {:ok, listener} = meta[:adapter].lookup_listener(transaction.blockchain_transaction.hash)
      assert %{listener: _, pid: blockchain_listener_pid} = listener

      ref = Process.monitor(tracker_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id, preload: :blockchain_transaction)
          assert transaction.status == TransactionState.confirmed()
          assert transaction.blockchain_transaction.confirmed_at_block_number == 20
      end
    end

    test "submits a childchain transaction to the blockchain subapp (hot wallet plasma to blockchain plasma address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      childchain_identifier = BlockchainHelper.childchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => rootchain_identifier,
        "childchain_identifier" => childchain_identifier,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Blockchain.create(admin, attrs, {true, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_transaction.rootchain_identifier == rootchain_identifier
      assert transaction.blockchain_transaction.childchain_identifier == childchain_identifier
      assert transaction.blockchain_transaction.block_number == nil

      # Fast forward the blockchain manually to have the transaction confirmed.
      BlockchainState.update(rootchain_identifier, 20)

      {:ok, tracker_pid} =
        BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)

      assert Process.alive?(tracker_pid)

      {:ok, listener} = meta[:adapter].lookup_listener(transaction.blockchain_transaction.hash)
      assert %{listener: _, pid: blockchain_listener_pid} = listener

      ref = Process.monitor(tracker_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id, preload: :blockchain_transaction)
          assert transaction.status == TransactionState.confirmed()
          assert transaction.blockchain_transaction.confirmed_at_block_number == 20
      end
    end

    test "returns an error for a childchain transaction if there is no balance for the token" do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000999"
        )

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      childchain_identifier = BlockchainHelper.childchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => rootchain_identifier,
        "childchain_identifier" => childchain_identifier,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :insufficient_funds_in_hot_wallet} ==
               TransactionGate.Blockchain.create(admin, attrs, {true, true})
    end

    test "returns an error for a childchain transaction if there is not enough funds for the transaction" do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      childchain_identifier = BlockchainHelper.childchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => rootchain_identifier,
        "childchain_identifier" => childchain_identifier,
        "amount" => 125,
        "originator" => %System{}
      }

      assert {:error, :insufficient_funds_in_hot_wallet} ==
               TransactionGate.Blockchain.create(admin, attrs, {true, true})
    end

    test "returns an error when trying to exchange" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      token = insert(:external_blockchain_token)
      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "from_token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => identifier,
        "to_token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :blockchain_exchange_not_allowed} ==
               TransactionGate.Blockchain.create(admin, attrs, {true, true})
    end

    test "returns an error when amounts are not valid" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => identifier,
        "from_amount" => 1,
        "to_amount" => 2,
        "originator" => %System{}
      }

      assert TransactionGate.Blockchain.create(admin, attrs, {true, true}) ==
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
        insert(:external_blockchain_token,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "rootchain_identifier" => identifier,
        "amount" => 125,
        "originator" => %System{}
      }

      assert {:error, :insufficient_funds_in_hot_wallet} ==
               TransactionGate.Blockchain.create(admin, attrs, {true, true})
    end

    test "returns an error if the token is not a blockchain token" do
      admin = insert(:admin, global_role: "super_admin")
      token = insert(:token)

      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "rootchain_identifier" => identifier,
        "token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :token_not_blockchain_enabled} ==
               TransactionGate.Blockchain.create(admin, attrs, {true, true})
    end
  end

  describe "create_from_tracker/2" do
    test "creates the blockchain transaction and tracks it" do
      token = insert(:external_blockchain_token)
      identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      blockchain_transaction_attrs = %{
        hash: "01",
        rootchain_identifier: identifier,
        childchain_identifier: nil,
        status: BlockchainTransactionState.pending_confirmations(),
        block_number: 0,
        originator: %System{}
      }

      transaction_attrs = %{
        idempotency_token: Crypto.fake_eth_address(),
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.pending(),
        type: Transaction.external(),
        payload: %{},
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

      # Fast forward the blockchain manually to have the transaction confirmed.
      BlockchainState.update(identifier, 30)

      {:ok, transaction} =
        TransactionGate.Blockchain.create_from_tracker(
          blockchain_transaction_attrs,
          transaction_attrs
        )

      {:ok, pid} = BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)
      assert Process.alive?(pid)

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert transaction.status == TransactionState.confirmed()
      end
    end

    test "creates the local transaction and starts tracking the blockchain transaction" do
      token = insert(:external_blockchain_token)
      identifier = BlockchainHelper.rootchain_identifier()
      wallet = insert(:wallet)

      {:ok, deposit_wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      # Fast forward the blockchain manually to have the transaction confirmed.
      BlockchainState.update(identifier, 30)

      blockchain_transaction_attrs = %{
        hash: "01",
        rootchain_identifier: identifier,
        childchain_identifier: nil,
        status: BlockchainTransactionState.pending_confirmations(),
        block_number: 0,
        originator: %System{}
      }

      transaction_attrs = %{
        idempotency_token: Crypto.fake_eth_address(),
        from_amount: 1,
        to_amount: 1,
        status: TransactionState.pending(),
        type: Transaction.external(),
        payload: %{},
        from_token_uuid: token.uuid,
        to_token_uuid: token.uuid,
        to: wallet.address,
        from: nil,
        from_blockchain_address: Crypto.fake_eth_address(),
        to_blockchain_address: deposit_wallet.address,
        from_account: nil,
        to_account: nil,
        from_user: nil,
        to_user: nil,
        originator: %System{}
      }

      {:ok, transaction} =
        TransactionGate.Blockchain.create_from_tracker(
          blockchain_transaction_attrs,
          transaction_attrs
        )

      {:ok, pid} = BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)
      assert Process.alive?(pid)

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert transaction.status == TransactionState.confirmed()
          # Check balance
          {:ok, %{balances: [balance]}} = BalanceFetcher.all(%{"wallet" => wallet})
          assert balance[:amount] == 1
          assert balance[:token].uuid == token.uuid
      end
    end
  end

  describe "get_or_insert/1" do
    test "returns a newly inserted local transaction if the idempotency_token is new" do
      token = insert(:token)
      wallet = insert(:wallet)

      {:ok, deposit_wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        "idempotency_token" => tx_hash,
        "from_amount" => 1,
        "to_amount" => 1,
        "status" => TransactionState.pending(),
        "type" => Transaction.external(),
        "confirmations_count" => 0,
        "blk_number" => 1,
        "payload" => %{},
        "blockchain_metadata" => %{},
        "from_token_uuid" => token.uuid,
        "to_token_uuid" => token.uuid,
        "to" => wallet.address,
        "from" => nil,
        "from_blockchain_address" => Crypto.fake_eth_address(),
        "to_blockchain_address" => deposit_wallet.address,
        "from_account" => nil,
        "to_account" => nil,
        "from_user" => nil,
        "to_user" => nil,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Blockchain.get_or_insert(attrs)
      assert transaction.idempotency_token == tx_hash
    end

    test "returns the existing local transaction if the idempotency_token already exists" do
      token = insert(:token)
      wallet = insert(:wallet)

      {:ok, deposit_wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      tx_hash = Crypto.fake_eth_address()

      attrs = %{
        "idempotency_token" => tx_hash,
        "from_amount" => 1,
        "to_amount" => 1,
        "status" => TransactionState.pending(),
        "type" => Transaction.external(),
        "confirmations_count" => 0,
        "blk_number" => 1,
        "payload" => %{},
        "blockchain_metadata" => %{},
        "from_token_uuid" => token.uuid,
        "to_token_uuid" => token.uuid,
        "to" => wallet.address,
        "from" => nil,
        "from_blockchain_address" => Crypto.fake_eth_address(),
        "to_blockchain_address" => deposit_wallet.address,
        "from_account" => nil,
        "to_account" => nil,
        "from_user" => nil,
        "to_user" => nil,
        "originator" => %System{}
      }

      {:ok, transaction_1} = TransactionGate.Blockchain.get_or_insert(attrs)
      {:ok, transaction_2} = TransactionGate.Blockchain.get_or_insert(attrs)

      assert transaction_1.idempotency_token == tx_hash
      assert transaction_1.idempotency_token == transaction_2.idempotency_token
    end

    test "returns :idempotency_token if the idempotency_token is not given" do
      assert TransactionGate.Blockchain.get_or_insert(%{}) ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `idempotency_token` is required."}
    end
  end
end
