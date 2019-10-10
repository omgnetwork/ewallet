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

defmodule EWalletConfig.BlockchainIntervalSettingsLoaderTest do
  use EWalletConfig.SchemaCase, async: false
  alias EWalletConfig.BlockchainIntervalSettingsLoader

  @app :my_blockchain_interval_settings_app

  setup do
    :ok = Application.put_env(@app, :address_tracker, __MODULE__)
    :ok
  end

  def set_interval(mode, interval) do
    send(self(), {:set_interval_called, mode, interval})

    # Kernel.send/2 returns the sent message but the actual address tracker would return :ok
    :ok
  end

  describe "load/2" do
    test "calls the address tracker's set_interval/2 when blockchain_sync_interval is updated" do
      :ok = Application.put_env(@app, :blockchain_sync_interval, 1000)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_sync_interval)

      assert res == :ok
      assert_received {:set_interval_called, :sync, 1000}
    end

    test "calls the address tracker's set_interval/2 when blockchain_poll_interval is updated" do
      :ok = Application.put_env(@app, :blockchain_poll_interval, 1000)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_poll_interval)

      assert res == :ok
      assert_received {:set_interval_called, :poll, 1000}
    end
  end
end
