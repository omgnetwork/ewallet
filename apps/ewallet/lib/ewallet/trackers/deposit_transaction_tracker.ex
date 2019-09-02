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

# defmodule EWallet.DepositTransactionTracker do
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

#   # TODO: only starts when blockchain is enabled

#   @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
#   def start_link(opts) do
#     name = Keyword.get(opts, :name, __MODULE__)
#     attrs = Keyword.get(opts, :attrs, %{})
#     GenServer.start_link(__MODULE__, attrs, name: name)
#   end

#   def init(%{transaction: transaction} = attrs) do
#     {:ok,
#      %{
#        transaction: transaction,
#        registry: attrs[:registry]
#      }}
#   end

#   def handle_cast(:start_polling, state) do
#     poll(state)
#   end
# end
