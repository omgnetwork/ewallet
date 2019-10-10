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

defmodule EWalletConfig.BlockchainIntervalSettingsLoader do
  @moduledoc """
  Perform necessary changes to the system to reflect the changed blockchain interval settings.
  """
  @behaviour EWalletConfig.Loader

  @impl EWalletConfig.Loader
  @spec load(Application.app(), EWalletConfig.Setting.key()) :: :ok
  def load(app, :blockchain_sync_interval) do
    tracker = Application.get_env(app, :address_tracker)
    interval = Application.get_env(app, :blockchain_sync_interval)

    tracker.set_interval(:sync, interval)
  end

  def load(app, :blockchain_poll_interval) do
    tracker = Application.get_env(app, :address_tracker)
    interval = Application.get_env(app, :blockchain_poll_interval)

    tracker.set_interval(:poll, interval)
  end

  def load(app, :blockchain_transaction_poll_interval) do
    registry = Application.get_env(app, :transaction_registry)
    interval = Application.get_env(app, :blockchain_transaction_poll_interval)

    registry.set_listener_interval(interval)
  end

  def load(app, :blockchain_deposit_pooling_interval) do
    tracker = Application.get_env(app, :deposit_wallet_pooling_tracker)
    interval = Application.get_env(app, :blockchain_deposit_pooling_interval)

    tracker.set_interval(interval)
  end
end
