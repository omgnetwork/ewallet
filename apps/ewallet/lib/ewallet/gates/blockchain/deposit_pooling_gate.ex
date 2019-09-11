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
  alias EWallet.{BlockchainHelper, TransactionRegistry, TransactionTracker}

  alias EWalletDB.{
    Token,
    BlockchainWallet,
    BlockchainDepositWalletBalance,
    DepositTransaction,
    Helpers.Preloader,
    TransactionState
  }

  alias ActivityLogger.System

  def move_deposits_to_pooled_funds(blockchain_identifier) do
    # for each token, get all deposit wallets that have balance > 0
    # get total value in all deposit wallets and in hot wallet
    # if sum > 3% of hot wallet, transfer until amount is 0.5%
    primary_token_address = BlockchainHelper.adapter().helper().default_token()[:address]

    {[primary_token], secondary_tokens} =
      blockchain_identifier
      |> Token.all_blockchain()
      |> Enum.split(fn t -> t.blockchain_address == primary_token_address end)

    hot_wallet = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)

    # TODO: get real gas cost
    check_and_move_primary(primary_token, hot_wallet, 20_000_000_000, 21_000)
    check_and_move_secondary(secondary_tokens, hot_wallet, 20_000_000_000, 90_000)
  end

  defp check_and_move_primary(primary_token, gas_price, gas_limit) do
    # DOING: Rapatriate Ethereum
    [primary_token]
    |> BlockchainDepositWalletBalance.all_with_balances(blockchain_identifier)
    |> Enum.map(fn balance ->
      gas_cost = gas_price * gas_limit
      amount = balance.amount - gas_cost

      # TODO: Check for pending transaction with same from / to / status = pending
      with true <- amount > 0 || {:error, :invalid_amount},
           # TODO: Query balance from blockchain and check > 0
           {:ok, transaction} <-
             DepositTransaction.insert(%{
               type: DepositTransaction.incoming(),
               amount: amount,
               token_uuid: primary_token.uuid,
               cost: gas_price,
               limit: gas_limit,
               from_deposit_wallet_address: balance.blockchain_deposit_wallet_address,
               to_blockchain_wallet_address: hot_wallet.address,
               blockchain_identifier: blockchain_identifier,
               originator: %System{}
             }),
           transaction <- Preloader.preload(transaction, [:token]),
           balance <-
             Preloader.preload(balance, blockchain_deposit_wallet: [:blockchain_hd_wallet]),
           {:ok, tx_hash} <- submit(transaction, balance),
           {:ok, transaction} <-
             TransactionState.transition_to(
               :from_deposit_to_pooled,
               TransactionState.blockchain_submitted(),
               transaction,
               %{blockchain_tx_hash: tx_hash, originator: %System{}}
             ),
           :ok <-
             TransactionRegistry.start_tracker(TransactionTracker, %{
               transaction: transaction,
               transaction_type: :from_deposit_to_pooled
             }) do
        {:ok, transaction}
      else
        error ->
          error
      end
    end)
  end

  # TODO: Rapatriate ERC-20 token
  defp check_and_move_secondary(tokens, gas_price, gas_limit) do
    secondary_tokens
    |> BlockchainDepositWalletBalance.all_with_balances(blockchain_identifier)
    |> Enum.map(fn balance -> balance end)
  end

  defp submit(transaction, %{blockchain_deposit_wallet: blockchain_deposit_wallet} = balance) do
    blockchain_adapter = BlockchainHelper.adapter()
    node_adapter = Application.get_env(:ewallet, :node_adapter)

    attrs = %{
      from: transaction.from_deposit_wallet_address || transaction.from_deposit_wallet_address,
      to: transaction.to_blockchain_wallet_address || transaction.to_deposit_wallet_address,
      amount: transaction.amount,
      contract_address: transaction.token.blockchain_address,
      gas_limit: transaction.limit,
      gas_price: transaction.price,
      wallet: %{
        wallet_uuid: blockchain_deposit_wallet.blockchain_hd_wallet.keychain_uuid,
        account_ref: blockchain_deposit_wallet.path_ref,
        deposit_ref: 0
      }
    }

    blockchain_adapter.call({:send, attrs}, node_adapter)
  end
end
