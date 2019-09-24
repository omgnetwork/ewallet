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

defmodule EWallet.AddressTrackerTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  import Ecto.Query
  alias EWallet.{AddressTracker, BalanceFetcher, BlockchainHelper, BlockchainDepositWalletGate}

  alias EWalletDB.{
    BlockchainDepositWallet,
    BlockchainWallet,
    Transaction,
    TransactionState,
    Token,
    Repo
  }

  alias Keychain.Wallet
  alias ActivityLogger.System
  alias Utils.Helpers.Crypto

  @minimum_confirmation_counts 10

  describe "start_link/1" do
    test "starts a new server" do
      _hot_wallet = insert(:blockchain_wallet, type: "hot")

      assert {:ok, pid} =
               AddressTracker.start_link(
                 name: :test_address_tracker,
                 blockchain_identifier: "any_blockchain_identifier"
               )

      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits without addresses" do
      expected = %{
        addresses: %{},
        blk_number: 0,
        blk_retries: 0,
        blk_syncing_save_count: 0,
        blk_syncing_save_interval: 5,
        blockchain_identifier: "any_blockchain_identifier",
        contract_addresses: [],
        node_adapter: nil,
        interval: 50,
        timer: nil,
        stop_once_synced: false
      }

      assert AddressTracker.init(blockchain_identifier: "any_blockchain_identifier") ==
               {:ok, expected, {:continue, :start_polling}}
    end

    test "inits with addresses" do
      hot_wallet =
        insert(:blockchain_wallet, type: "hot", blockchain_identifier: "any_blockchain_identifier")

      deposit_wallet =
        insert(:blockchain_deposit_wallet, blockchain_identifier: "any_blockchain_identifier")

      token =
        insert(:token,
          blockchain_identifier: "any_blockchain_identifier",
          blockchain_address: Crypto.fake_eth_address()
        )

      expected = %{
        addresses: %{
          hot_wallet.address => nil,
          deposit_wallet.address => deposit_wallet.wallet.address
        },
        blk_number: 0,
        blk_retries: 0,
        blk_syncing_save_count: 0,
        blk_syncing_save_interval: 5,
        blockchain_identifier: "any_blockchain_identifier",
        node_adapter: :fake_adapter,
        contract_addresses: [
          token.blockchain_address
        ],
        interval: 50,
        timer: nil,
        stop_once_synced: false
      }

      assert AddressTracker.init(
               blockchain_identifier: "any_blockchain_identifier",
               node_adapter: :fake_adapter
             ) ==
               {:ok, expected, {:continue, :start_polling}}
    end
  end

  describe "handle_call/3 with :register_address" do
    test "registers an address to track" do
      {:ok, pid} =
        AddressTracker.start_link(
          name: :test_address_tracker,
          blockchain_identifier: "any_blockchain_identifier"
        )

      assert AddressTracker.register_address("blockchain_address", "internal_address", pid) == :ok

      state = :sys.get_state(pid)

      assert state[:addresses] == %{
               "blockchain_address" => "internal_address"
             }

      assert GenServer.stop(pid) == :ok
    end
  end

  describe "run/1 through polling" do
    test "processes and stores all relevant transactions" do
      adapter = Application.get_env(:ewallet_db, :blockchain_adapter)
      blockchain_identifier = adapter.helper().identifier()

      default_token =
        insert(:token, %{
          blockchain_address: BlockchainHelper.adapter().helper().default_token().address,
          blockchain_status: Token.blockchain_status_confirmed()
        })

      {:ok, {_address, _public_key}} = Wallet.generate()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)

      wallet = insert(:wallet)

      {:ok, wallet} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      deposit_wallet = BlockchainDepositWallet.get_last_for(wallet)

      erc20_token =
        insert(:token,
          blockchain_address: Crypto.fake_eth_address(),
          blockchain_identifier: blockchain_identifier
        )

      other_address = Crypto.fake_eth_address()

      assert {:ok, pid} =
               AddressTracker.start_link(
                 name: :test_address_tracker_1,
                 node_adapter:
                   {:dumb_receiver, EthBlockchain.DumbReceivingAdapter,
                    [
                      %{
                        hot_wallet_address: hot_wallet.address,
                        deposit_wallet_address: deposit_wallet.address,
                        erc20_address: erc20_token.blockchain_address,
                        other_address: other_address
                      }
                    ]},
                 blockchain_identifier: blockchain_identifier,
                 stop_once_synced: true
               )

      state = :sys.get_state(pid)

      assert state[:addresses] == %{
               hot_wallet.address => nil,
               deposit_wallet.address => wallet.address
             }

      # Because we're passing stop_once_synced: true, the tracker will
      # stop once it reaches the end of the chain
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transactions = Repo.all(from(Transaction, order_by: :blockchain_tx_hash))
          assert length(transactions) == 9

          # All transactions are defined in the DumbReceivingAdapter,
          # for ease of reading, the details of each transaction are present
          # before each set of assertions as
          # build_eth_transaction(blk_number, tx_hash, from, to, value)
          # or
          # build_erc20_transaction(blk_number, tx_hash, erc20_address, from, to, value)

          # build_eth_transaction(0, "01", hot_wallet_address, other_address, 1_000)
          transactions
          |> Enum.at(0)
          |> assert_transaction(
            hot_wallet.address,
            other_address,
            nil,
            nil,
            0,
            "01",
            default_token.uuid,
            1_000
          )

          # build_eth_transaction(0, "02", hot_wallet_address, other_address, 1_000)
          transactions
          |> Enum.at(1)
          |> assert_transaction(
            hot_wallet.address,
            other_address,
            nil,
            nil,
            0,
            "02",
            default_token.uuid,
            1_000
          )

          # build_eth_transaction(0, "03", hot_wallet_address, other_address, 1_000)
          transactions
          |> Enum.at(2)
          |> assert_transaction(
            hot_wallet.address,
            other_address,
            nil,
            nil,
            0,
            "03",
            default_token.uuid,
            1_000
          )

          # build_eth_transaction(0, "04", other_address, deposit_wallet_address, 1_000)
          transactions
          |> Enum.at(3)
          |> assert_transaction(
            other_address,
            deposit_wallet.address,
            nil,
            wallet.address,
            0,
            "04",
            default_token.uuid,
            1_000
          )

          # build_eth_transaction(0, "04", other_address, Crypto.fake_eth_address(), 1_000)
          # This one is ignored since not relevant
          assert Transaction.get_by(blockchain_tx_hash: "05") == nil

          # build_eth_transaction(1, "11", other_address, deposit_wallet_address, 1_337_000)
          transactions
          |> Enum.at(4)
          |> assert_transaction(
            other_address,
            deposit_wallet.address,
            nil,
            wallet.address,
            1,
            "11",
            default_token.uuid,
            1_337_000
          )

          # build_erc20_transaction(1, "12", erc20_address, hot_wallet_address,
          #   other_address, 1_000)
          transactions
          |> Enum.at(5)
          |> assert_transaction(
            hot_wallet.address,
            other_address,
            nil,
            nil,
            1,
            "12",
            erc20_token.uuid,
            1_000
          )

          # build_erc20_transaction(1, "13", erc20_address, other_address,
          #  deposit_wallet_address, 1_000)
          transactions
          |> Enum.at(6)
          |> assert_transaction(
            other_address,
            deposit_wallet.address,
            nil,
            wallet.address,
            1,
            "13",
            erc20_token.uuid,
            1_000
          )

          # build_erc20_transaction(1, "13", erc20_address, other_address, other_address, 1_000)
          # This one is ignored since not relevant
          assert Transaction.get_by(blockchain_tx_hash: "14") == nil

          # build_erc20_transaction(1, "13", erc20_address, other_address,
          #   deposit_wallet_address, 1_000),

          # build_eth_transaction(2, "21", other_address, deposit_wallet_address, 1_000),
          transactions
          |> Enum.at(7)
          |> assert_transaction(
            other_address,
            deposit_wallet.address,
            nil,
            wallet.address,
            2,
            "21",
            default_token.uuid,
            1_000
          )

          # build_erc20_transaction(2, "22", erc20_address, other_address,
          #   deposit_wallet_address, 25_000)
          transactions
          |> Enum.at(8)
          |> assert_transaction(
            other_address,
            deposit_wallet.address,
            nil,
            wallet.address,
            2,
            "22",
            erc20_token.uuid,
            25_000
          )

          # Check the balance of the deposit wallet to ensure the
          # funds have been received internally
          {:ok, %{balances: balances} = _wallet} = BalanceFetcher.all(%{"wallet" => wallet})

          balances =
            Enum.map(balances, fn balance ->
              {balance[:amount], balance[:token].uuid}
            end)

          assert Enum.member?(balances, {1_000 + 1_337_000 + 1_000, default_token.uuid})
          assert Enum.member?(balances, {1_000 + 25_000, erc20_token.uuid})
      end

      refute Process.alive?(pid)
    end
  end

  # It's a private helper function and we're doing a lot of assertions
  # credo:disable-for-next-line Credo.Check.Refactor.FunctionArity
  defp assert_transaction(
         transaction,
         from_bc,
         to_bc,
         from,
         to,
         blk_number,
         tx_hash,
         token_uuid,
         amount
       ) do
    assert transaction.blockchain_tx_hash == tx_hash
    assert transaction.status == TransactionState.confirmed()
    assert transaction.confirmations_count > @minimum_confirmation_counts
    assert transaction.from_blockchain_address == from_bc
    assert transaction.to_blockchain_address == to_bc
    assert transaction.from == from
    assert transaction.to == to
    assert transaction.blk_number == blk_number
    assert transaction.from_token_uuid == token_uuid
    assert transaction.to_token_uuid == token_uuid
    assert transaction.from_amount == amount
    assert transaction.to_amount == amount
  end
end
