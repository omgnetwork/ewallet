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
  use GenServer, restart: :transient
  require Logger
  alias EWallet.DepositPoolingGate

  # Default pooling to 1 hour
  @default_pooling_interval 60 * 60 * 1000

  #
  # Client APIs
  #

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec set_interval(non_neg_integer(), GenServer.server()) :: :ok
  def set_interval(interval, pid \\ __MODULE__) do
    GenServer.cast(pid, {:set_interval, interval})
  end

  #
  # GenServer callbacks
  #

  def init(opts) do
    # Notice we're not using Application.get_env/3 here, and use `|| false` instead? It's because
    # we populate this config from database, which may return nil. This function treats the nil
    # as an existing value, and so get_env/3 would never pick up the passed default here.
    case Application.get_env(:ewallet, :blockchain_enabled, true) do
      true ->
        state = %{
          blockchain_identifier: Keyword.fetch!(opts, :blockchain_identifier),
          pooling_interval:
            Application.get_env(:ewallet, :blockchain_deposit_pooling_interval) ||
              @default_pooling_interval,
          timer: nil
        }

        {:ok, state, {:continue, :start_polling}}

      false ->
        _ = Logger.info("DepositWalletPoolingTracker did not start. Blockchain is not enabled.")
        :ignore
    end
  end

  def handle_continue(:start_polling, state) do
    _ = Logger.info("DepositWalletPoolingTracker started and is now polling.")
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  def handle_cast({:set_interval, interval}, state) do
    state = %{state | pooling_interval: interval}

    # Cancel the existing timer if there's one
    _ = state.timer && Process.cancel_timer(state.timer)

    timer = schedule_next_poll(state)
    {:noreply, %{state | timer: timer}}
  end

  #
  # Polling management
  #

  # Skip if interval is 0 or less
  defp poll(%{pooling_interval: interval} = state) when interval <= 0 do
    {:noreply, %{state | timer: nil}}
  end

  defp poll(state) do
    _ = Logger.debug("Triggering deposit wallet pooling.")

    _ =
      case DepositPoolingGate.move_deposits_to_pooled_funds(state.blockchain_identifier) do
        {:ok, _} ->
          :noop

        error ->
          _ =
            Logger.error(
              "Errored trying to pool funds from deposit wallets." <>
                " Retrying in #{state.pooling_interval} ms. Got: #{inspect(error)}."
            )
      end

    timer = schedule_next_poll(state)
    {:noreply, %{state | timer: timer}}
  end

  defp schedule_next_poll(state) do
    case state.pooling_interval do
      interval when interval > 0 ->
        Process.send_after(self(), :poll, interval)

      interval ->
        _ = Logger.info("Deposit wallet pooling has paused because the interval is #{interval}.")
        nil
    end
  end
end
