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

defmodule EWallet.DepositPoolingGate do
  @moduledoc """
  Monitors deposit wallets and moves the funds into a pooled wallet when criteria are met.
  """
  require Logger
  alias ActivityLogger.System
  alias EWallet.{AmountFormatter, BlockchainHelper, BlockchainDepositWalletGate}

  alias EWalletDB.{
    Token,
    BlockchainWallet,
    BlockchainDepositWallet,
    BlockchainDepositWalletCachedBalance,
    DepositTransaction,
    Helpers.Preloader,
    Transaction
  }

  alias Keychain.Wallet

  # TODO: get real gas price
  @gas_price 40_000_000_000
  @gas_limit_eth 21_000
  @gas_limit_erc20 90_000

  @doc """
  Checks all deposit wallets for excess funds and transfer them to the hot wallet.
  """
  @spec move_deposits_to_pooled_funds(String.t()) :: {:ok, [%DepositTransaction{}]}
  def move_deposits_to_pooled_funds(blockchain_identifier) do
    primary_token_address = BlockchainHelper.adapter().helper().default_token()[:address]
    pool = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)

    # We loop by token because it's likely we pool per specific token than a specific wallet.
    # E.g. some tokens have more deposits than others, or the hot wallet may run out of one token
    # more often than others. In this case, loop by token is O(n) while loop by wallet is O(n2).
    pool_transactions =
      blockchain_identifier
      |> Token.all_blockchain()
      |> Enum.flat_map(fn token ->
        case token.blockchain_address do
          ^primary_token_address ->
            pool_token_deposits(token, pool, blockchain_identifier, @gas_price, @gas_limit_eth)

          _ ->
            pool_token_deposits(token, pool, blockchain_identifier, @gas_price, @gas_limit_erc20)
        end
      end)

    {:ok, pool_transactions}
  end

  defp pool_token_deposits(token, hot_wallet, blockchain_identifier, gas_price, gas_limit) do
    token
    |> BlockchainDepositWalletCachedBalance.all_for_token(blockchain_identifier)
    |> Enum.filter(fn balance ->
      # TODO: Pool only if the deposit wallet has 3% of primary hot wallet's funds
      poolable_amount(balance, gas_price, gas_limit) > 0
    end)
    |> Enum.map(fn balance ->
      attrs = %{
        type: DepositTransaction.outgoing(),
        amount: poolable_amount(balance, gas_price, gas_limit),
        token_uuid: token.uuid,
        from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
        to_blockchain_address: hot_wallet.address,
        blockchain_identifier: blockchain_identifier,
        originator: %System{}
      }

      _ =
        Logger.info(
          "Pooling #{AmountFormatter.format(attrs.amount, token.subunit_to_unit)}" <>
            " #{token.symbol} from #{attrs.from_deposit_wallet_address}" <>
            " into #{attrs.to_blockchain_address}."
        )

      with {:ok, transaction} <- DepositTransaction.insert(attrs),
           {:ok, tx_hash} <- submit_blockchain(transaction, balance, gas_price, gas_limit),
           {:ok, transaction} <- set_transaction_hash(transaction, tx_hash) do
        {:ok, transaction}
      else
        error -> error
      end
    end)
  end

  defp set_transaction_hash(transaction, tx_hash) do
    DepositTransaction.update(transaction, %{blockchain_tx_hash: tx_hash, originator: %System{}})
  end

  # Checks the poolable amount by subtracting the balance amount from all ongoing
  # pooling transactions (transactions going out of the deposit wallet).
  defp poolable_amount(balance, gas_price, gas_limit) do
    pending_amount =
      [
        from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
        token_uuid: balance.token_uuid
      ]
      |> DepositTransaction.all_unfinalized_by()
      |> Enum.reduce(0, fn dt, sum -> sum + dt.amount end)

    max_gas_cost = gas_price * gas_limit
    balance.amount - pending_amount - max_gas_cost
  end

  defp submit_blockchain(transaction, balance, gas_price, gas_limit) do
    transaction = Preloader.preload(transaction, [:token])

    balance =
      Preloader.preload(balance, blockchain_deposit_wallet: [:blockchain_hd_wallet, :wallet])

    attrs = %{
      from: transaction.from_deposit_wallet_address || transaction.from_blockchain_address,
      to: transaction.to_blockchain_address || transaction.to_deposit_wallet_address,
      amount: transaction.amount,
      contract_address: transaction.token.blockchain_address,
      gas_limit: gas_limit,
      gas_price: gas_price,
      wallet: %{
        keychain_uuid: balance.blockchain_deposit_wallet.blockchain_hd_wallet.keychain_uuid,
        derivation_path: Wallet.root_hd_path_private(),
        wallet_ref: balance.blockchain_deposit_wallet.wallet.relative_hd_path,
        deposit_ref: balance.blockchain_deposit_wallet.relative_hd_path
      }
    }

    BlockchainHelper.call(:send, attrs)
  end

  @doc """
  Performs necessary operations to reflect the received blockchain transaction onto
  the DepositTransaction. Does 3 things:

    1. Creates a new incoming deposit transaction if fund is coming into the deposit wallet.
    2. Associate the blockchain transaction with the deposit transaction if fund is going out.
    3. Refresh the deposit wallet balance.

  Does nothing if the given transaction is not related to the deposit wallet.
  """
  @spec on_blockchain_transaction_received(%Transaction{}) :: :ok
  def on_blockchain_transaction_received(transaction) do
    from_deposit_wallet = BlockchainDepositWallet.get(transaction.from_blockchain_address)
    to_deposit_wallet = BlockchainDepositWallet.get(transaction.to_blockchain_address)

    case {from_deposit_wallet, to_deposit_wallet} |> IO.inspect() do
      # Not a deposit transaction. Do nothing.
      {nil, nil} ->
        :ok

      # Handles incoming deposit transaction
      {nil, to_deposit_wallet} ->
        Logger.info("An incoming deposit transaction detected: #{to_deposit_wallet.address}.")
        _ = create_incoming_deposit_transaction(transaction)
        _ = refresh_balances(transaction, to_deposit_wallet)
        :ok

      # Handles outgoing deposit transaction (a pooling transaction to the hot wallet)
      {from_deposit_wallet, nil} ->
        _ = match_outgoing_deposit_transaction(transaction)
        _ = refresh_balances(transaction, from_deposit_wallet)
        :ok
    end
  end

  defp create_incoming_deposit_transaction(transaction) do
    DepositTransaction.insert(%{
      type: DepositTransaction.incoming(),
      amount: transaction.to_amount,
      token_uuid: transaction.to_token_uuid,
      transaction_uuid: transaction.uuid,
      from_blockchain_address: transaction.from_blockchain_address,
      to_deposit_wallet_address: transaction.to_blockchain_address,
      blockchain_identifier: transaction.blockchain_identifier,
      blockchain_tx_hash: transaction.blockchain_tx_hash,
      originator: %System{}
    })
    |> IO.inspect()
  end

  defp match_outgoing_deposit_transaction(transaction) do
    deposit_transaction =
      DepositTransaction.get_by(
        type: DepositTransaction.outgoing(),
        blockchain_identifier: transaction.blockchain_identifier,
        blockchain_tx_hash: transaction.blockchain_tx_hash
      )

    case deposit_transaction do
      # The blockchain tx hash is not related to any outgoing deposit transaction, skipping.
      nil ->
        :noop

      # The deposit transaction already has an associated transaction, do not try to update.
      %{transaction_uuid: tx_uuid} when not is_nil(tx_uuid) ->
        :noop

      # Found a matching deposit transaction that hasn't been associated, associate it.
      deposit_transaction ->
        DepositTransaction.update(deposit_transaction, %{
          transaction_uuid: transaction.uuid,
          originator: %System{}
        })

        :ok
    end
  end

  defp refresh_balances(transaction, deposit_wallet) do
    transaction = Preloader.preload(transaction, :to_token)

    BlockchainDepositWalletGate.refresh_balances(
      deposit_wallet,
      transaction.to_token
    )
  end
end
