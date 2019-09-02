# # Copyright 2018-2019 OmiseGO Pte Ltd
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #     http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.

# defmodule EWallet.DepositWalletTracker do
#   @moduledoc """

#   """
#   use GenServer
#   require Logger

#   alias EWallet.{
#     BlockchainHelper,
#     BlockchainAddressFetcher,
#     BlockchainStateGate,
#     BlockchainTransactionGate
#   }

#   alias EWalletDB.{BlockchainState, Token, Transaction, TransactionState}
#   alias ActivityLogger.System

#   @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
#   def start_link(opts) do
#     name = Keyword.get(opts, :name, __MODULE__)
#     attrs = Keyword.get(opts, :attrs, %{})
#     GenServer.start_link(__MODULE__, attrs, name: name)
#   end

#   def init(%{
#     deposit_wallet_address: deposit_wallet_address,
#     blockchain_identifier: blockchain_identifier
#   } = attrs) do
#     {:ok, %{
#       blockchain_identifier: blockchain_identifier,
#       deposit_wallet_address: deposit_wallet_address,
#       transaction: attrs[:transaction]
#     }}
#   end

#   def handle_cast({:register, address}, %{blockchain_identifier: blockchain_identifier} = state) do
#     tokens = Token.all_blockchain(blockchain_identifier)
#     deposit_wallet = BlockchainDepositWallet.get(address)
#     balances = BlockchainBalanceFetcher.all([deposit_wallet.address], tokens)

#     {:ok, stored_balance} = BlockchainDepositWalletBalance.create_or_update(deposit_wallet, balances)

#     {:no_reply, :ok, state}
#   end

#   def register(%Transaction{to: to} = transaction) do

#   end

#   defp run(
#          %{

#          } = state
#        ) do
#       # for each token, get all deposit wallets that have balance > 0
#       # get total value in all deposit wallets and in hot wallet
#       # if sum > 3% of hot wallet, transfer until amount is 0.5%

#     end
#   end
# end
