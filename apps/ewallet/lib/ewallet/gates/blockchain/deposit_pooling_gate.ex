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
  alias EWallet.{BlockchainHelper, TransactionTracker}

  alias EWalletDB.{
    Token,
    BlockchainWallet,
    BlockchainDepositWalletCachedBalance,
    DepositTransaction,
    Helpers.Preloader,
    TransactionState
  }

  alias Keychain.Wallet

  # TODO: get real gas price
  @gas_price 40_000_000_000
  @gas_limit_eth 21_000
  @gas_limit_erc20 90_000

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
        Logger.debug("Checking deposit wallet balances for token #{token.symbol}.")

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
      poolable_amount(balance, gas_price, gas_limit) > 0
    end)
    |> Enum.map(fn balance ->
      attrs = %{
        type: DepositTransaction.outgoing(),
        amount: poolable_amount(balance, gas_price, gas_limit),
        token_uuid: token.uuid,
        gas_price: gas_price,
        gas_limit: gas_limit,
        from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
        to_blockchain_wallet_address: hot_wallet.address,
        blockchain_identifier: blockchain_identifier,
        originator: %System{}
      }

      case DepositTransaction.insert(attrs) do
        {:ok, transaction} ->
          # TODO: Pool only if the deposit wallet has 3% of primary hot wallet's funds
          with {:ok, tx_hash} <- submit(transaction, balance),
               {:ok, transaction} <-
                 TransactionState.transition_to(
                   :from_deposit_to_pooled,
                   TransactionState.blockchain_submitted(),
                   transaction,
                   %{blockchain_tx_hash: tx_hash, originator: %System{}}
                 ),
               {:ok, _pid} <- TransactionTracker.start(transaction, :from_deposit_to_pooled) do
            {:ok, transaction}
          else
            error -> error
          end

        error ->
          error
      end
    end)
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

  defp submit(transaction, balance) do
    transaction = Preloader.preload(transaction, [:token])
    balance = Preloader.preload(balance, blockchain_deposit_wallet: [:blockchain_hd_wallet, :wallet])

    attrs = %{
      from: transaction.from_deposit_wallet_address || transaction.from_blockchain_wallet_address,
      to: transaction.to_blockchain_wallet_address || transaction.to_deposit_wallet_address,
      amount: transaction.amount,
      contract_address: transaction.token.blockchain_address,
      gas_limit: transaction.gas_limit,
      gas_price: transaction.gas_price,
      wallet: %{
        keychain_uuid: balance.blockchain_deposit_wallet.blockchain_hd_wallet.keychain_uuid,
        derivation_path: Wallet.root_hd_path_private(),
        wallet_ref: balance.blockchain_deposit_wallet.wallet.relative_hd_path,
        deposit_ref: balance.blockchain_deposit_wallet.relative_hd_path
      }
    }

    BlockchainHelper.call(:send, attrs)
  end
end
