# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletConfig.BlockchainSettingsLoader do
  @moduledoc """
  Perform necessary changes to the system to reflect the changed blockchain settings.
  """
  require Logger

  @trackers [
    EWallet.AddressTracker,
    EWallet.DepositWalletPoolingTracker
  ]

  def load(app, supervisor \\ EWallet.Supervisor, trackers \\ @trackers) do
    case Application.get_env(app, :blockchain_enabled) || false do
      true -> start_trackers(trackers, supervisor)
      false -> stop_trackers(trackers)
    end

    :ok
  end

  defp start_trackers(trackers, supervisor) do
    Enum.each(trackers, fn tracker ->
      # `restart_child/2` starts a stopped child, not the same sense as a computer reboot.
      case Supervisor.restart_child(supervisor, tracker) do
        {:ok, :undefined} ->
          Logger.debug("Error starting #{inspect(tracker)}: The tracker is not supervised.")

        {:error, :running} ->
          Logger.debug("Error starting #{inspect(tracker)}. Already running.")

        {:error, error} ->
          Logger.debug("Error starting #{inspect(tracker)}: #{inspect(error)}")

        _ ->
          :ok
      end
    end)
  end

  defp stop_trackers(trackers) do
    Enum.each(trackers, fn tracker ->
      try do
        GenServer.stop(tracker, :normal)
      catch
        # Do nothing if the process is already stopped
        :exit, {:noproc, _} ->
          Logger.debug("Error stopping #{inspect(tracker)}. Already stopped.")

        :exit, error ->
          Logger.debug("Error stopping #{inspect(tracker)}: #{inspect(error)}")
      end
    end)
  end
end
