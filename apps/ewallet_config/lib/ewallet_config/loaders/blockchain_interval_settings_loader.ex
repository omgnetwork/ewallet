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

  @spec load(atom(), atom()) :: :ok
  def load(app, setting) do
    address_tracker = Application.get_env(app, :address_tracker)
    interval = Application.get_env(app, setting)

    case setting do
      :blockchain_sync_interval ->
        address_tracker.set_interval(:sync, interval)

      :blockchain_poll_interval ->
        address_tracker.set_interval(:poll, interval)
    end
  end
end
