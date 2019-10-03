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

defmodule EWallet.DepositWalletPoolingTracker do
  @moduledoc """
  Periodically triggers the check to move funds from deposit wallets to a hot wallet.
  """
  use GenServer
  require Logger
  alias EWallet.DepositPoolingGate

  # TODO: only starts when blockchain is enabled

  # TODO: make these numbers admin-configurable
  @default_interval 60 * 60 * 1_000

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    blockchain_identifier = Keyword.fetch!(opts, :blockchain_identifier)
    pooling_interval = Application.get_env(:ewallet, :deposit_pooling_interval, @default_interval)

    state = %{
      blockchain_identifier: blockchain_identifier,
      pooling_interval: pooling_interval,
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

  # Does not pool if the interval is too low
  defp poll(%{pooling_interval: interval} = state) when interval <= 0 do
    {:noreply, state}
  end

  defp poll(state) do
    case DepositPoolingGate.move_deposits_to_pooled_funds(state.blockchain_identifier) do
      {:ok, _} ->
        timer = Process.send_after(self(), :poll, state.pooling_interval)
        {:noreply, %{state | timer: timer}}

      error ->
        timer = Process.send_after(self(), :poll, state.pooling_interval)

        _ =
          Logger.error(
            "Errored trying to pool funds from deposit wallets." <>
              " Retrying in #{state.pooling_interval} ms. Got: #{inspect(error)}."
          )

        {:noreply, %{state | timer: timer}}
    end
  end
end
