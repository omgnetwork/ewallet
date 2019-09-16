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

defmodule EWallet.DepositWalletTracker do
  @moduledoc """

  """
  use GenServer
  require Logger
  alias EWallet.DepositPoolingGate

  # TODO: only starts when blockchain is enabled

  # TODO: make these numbers admin-configurable
  @checking_interval 600_000

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    attrs = Keyword.get(opts, :attrs, %{})
    GenServer.start_link(__MODULE__, attrs, name: name)
  end

  def init(attrs) do
    state = %{
      blockchain_identifier: attrs.blockchain_identifier,
      timer: nil
    }

    {:ok, state, {:continue, :start_polling}}
  end

  def handle_continue(:start_polling, state) do
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  defp poll(state) do
    case DepositPoolingGate.move_deposits_to_pooled_funds(state.blockchain_identifier) do
      {:ok, transactions} ->
        timer = Process.send_after(self(), :poll, @checking_interval)
        {:noreply, %{state | timer: timer}}

      error ->
        timer = Process.send_after(self(), :poll, @checking_interval)

        _ =
          Logger.error(
            "Errored trying to pool funds from deposit wallets." <>
              " Retrying in #{@checking_interval} ms. Got: #{inspect(error)}."
          )

        {:noreply, %{state | timer: timer}}
    end
  end
end
