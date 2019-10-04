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
  alias EWallet.{BlockchainHelper, BlockchainDepositWalletGate}

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

  @doc """
  Checks all deposit wallets for excess funds and transfer them to the hot wallet.
  """
  @spec move_deposits_to_pooled_funds(String.t()) :: {:ok, [%DepositTransaction{}]}
  def move_deposits_to_pooled_funds(blockchain_identifier) do
    primary_token_address = BlockchainHelper.adapter().helper().default_token().address
    hot_wallet = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)
    gas_price = BlockchainHelper.adapter().gas_helper().get_default_gas_price()

    gas_limit_erc20 =
      BlockchainHelper.adapter().gas_helper().get_default_gas_limit(:contract_transaction)

    gas_limit_eth =
      BlockchainHelper.adapter().gas_helper().get_default_gas_limit(:eth_transaction)

    # We loop by token because it's likely we pool per specific token than a specific wallet.
    # E.g. some tokens have more deposits than others, or the hot wallet may run out of one token
    # more often than others. In this case, loop by token is O(n) while loop by wallet is O(n2).
    {token_transactions, _, token_gas_used} =
      blockchain_identifier
      |> Token.all_blockchain()
      |> Enum.reject(fn token ->
        token.blockchain_address == primary_token_address
      end)
      |> pool_token_deposits(hot_wallet, blockchain_identifier, gas_price, gas_limit_erc20)

    # Do primary token last so other tokens have gas for the transfer
    {primary_token_transaction, _, _} =
      [blockchain_address: primary_token_address]
      |> Token.get_by()
      |> pool_token_deposits(
        hot_wallet,
        blockchain_identifier,
        gas_price,
        gas_limit_eth,
        token_gas_used
      )

    case primary_token_transaction do
      [transaction] -> {:ok, [transaction | token_transactions]}
      [] -> {:ok, token_transactions}
    end
  end

  defp pool_token_deposits(
         tokens,
         hot_wallet,
         blockchain_identifier,
         gas_price,
         gas_limit,
         reserve_amount \\ 0
       ) do
    balances =
      tokens
      |> List.wrap()
      |> Enum.flat_map(fn token ->
        token
        |> BlockchainDepositWalletCachedBalance.all_for_token(blockchain_identifier,
          preload: [:token]
        )
        |> Enum.filter(fn balance ->
          # TODO: Pool only if the deposit wallet has 3% of primary hot wallet's funds
          poolable_amount(balance, gas_price, gas_limit, reserve_amount) > 0
        end)
      end)

    Enum.reduce(balances, {[], [], 0}, fn balance, {transactions, errors, gas_used} ->
      # Deduct the gas from the pool amount only when the token is the primary token,
      # other tokens can be pooled for the full amount.
      pool_amount =
        case balance.token.blockchain_address ==
               BlockchainHelper.adapter().helper().default_token().address do
          true -> poolable_amount(balance, gas_price, gas_limit, reserve_amount)
          false -> poolable_amount(balance, 0, 0, reserve_amount)
        end

      attrs = %{
        type: DepositTransaction.outgoing(),
        amount: pool_amount,
        token_uuid: balance.token_uuid,
        from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
        to_blockchain_address: hot_wallet.address,
        blockchain_identifier: blockchain_identifier,
        originator: %System{}
      }

      with {:ok, transaction} <- DepositTransaction.insert(attrs),
           {:ok, tx_hash} <- submit_blockchain(transaction, balance, gas_price, gas_limit),
           {:ok, transaction} <- set_transaction_hash(transaction, tx_hash) do
        {[transaction | transactions], errors, gas_used + gas_price * gas_limit}
      else
        error -> {transactions, [error | errors], gas_used}
      end
    end)
  end

  defp set_transaction_hash(transaction, tx_hash) do
    DepositTransaction.update(transaction, %{blockchain_tx_hash: tx_hash, originator: %System{}})
  end

  # Checks the poolable amount by subtracting the balance amount from all ongoing
  # pooling transactions (transactions going out of the deposit wallet).
  defp poolable_amount(balance, gas_price, gas_limit, reserve_amount) do
    pending_amount =
      [
        from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
        token_uuid: balance.token_uuid
      ]
      |> DepositTransaction.all_unfinalized_by()
      |> Enum.reduce(0, fn dt, sum -> sum + dt.amount end)

    max_gas_cost = gas_price * gas_limit
    balance.amount - pending_amount - max_gas_cost - reserve_amount
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

    case {from_deposit_wallet, to_deposit_wallet} do
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
