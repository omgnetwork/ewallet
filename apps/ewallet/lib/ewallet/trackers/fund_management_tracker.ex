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

defmodule EWallet.FundManagementTracker do
  @moduledoc """

  """
  use GenServer
  require Logger

  alias EWallet.{
    BlockchainHelper,
    BlockchainAddressFetcher,
    BlockchainStateGate,
    BlockchainTransactionGate
  }

  alias EWalletDB.{BlockchainState, Token, Transaction, TransactionState}
  alias ActivityLogger.System

  # TODO: only starts when blockchain is enabled

  # TODO: make these numbers admin-configurable
  @checking_interval 600_000

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    attrs = Keyword.get(opts, :attrs, %{})
    GenServer.start_link(__MODULE__, attrs, name: name)
  end

  def init(%{blockchain_identifier: blockchain_identifier} = attrs) do
    {:ok,
     %{
       blockchain_identifier: blockchain_identifier
     }, {:continue, :start_polling}}
  end

  def handle_continue(:start_polling, state) do
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  defp poll(state) do
    case run(state) do
      new_state when is_map(new_state) ->
        timer = Process.send_after(self(), :poll, @checking_interval)
        {:noreply, %{new_state | timer: timer}}

      error ->
        error
    end
  end

  defp run(
         %{
           blockchain_identifier: blockchain_identifier
         } = state
       ) do
    FundManagementGate.move_deposits_to_pooled_funds(blockchain_identifier)
  end
end
