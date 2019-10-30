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

  defmodule MockTracker do
    @moduledoc """
    Simulates a blockchain tracker without running any business logic.

    This tracker simply sends the params back to the caller's mailbox. By sending the message
    back to the caller, we can easily assert that this tracker module got called using
    `assert_received/3`.
    """

    def set_interval(interval) do
      send(self(), {:called, :set_interval, interval})
      :ok
    end

    def set_interval(mode, interval) do
      send(self(), {:called, :set_interval, mode, interval})
      :ok
    end

    def set_listener_interval(interval) do
      send(self(), {:called, :set_listener_interval, interval})
      :ok
    end
  end

  setup do
    :ok = Application.put_env(@app, :address_tracker, __MODULE__.MockTracker)
    :ok = Application.put_env(@app, :deposit_wallet_pooling_tracker, __MODULE__.MockTracker)
    :ok = Application.put_env(@app, :transaction_registry, __MODULE__.MockTracker)
    :ok
  end

  describe "load/2" do
    test "calls the address tracker's set_interval/2 when blockchain_state_save_interval is updated" do
      interval = :rand.uniform(1000)
      :ok = Application.put_env(@app, :blockchain_state_save_interval, interval)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_state_save_interval)

      assert res == :ok
      assert_received {:called, :set_interval, :state_save, interval}
    end

    test "calls the address tracker's set_interval/2 when blockchain_sync_interval is updated" do
      interval = :rand.uniform(1000)
      :ok = Application.put_env(@app, :blockchain_sync_interval, interval)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_sync_interval)

      assert res == :ok
      assert_received {:called, :set_interval, :sync, interval}
    end

    test "calls the address tracker's set_interval/2 when blockchain_poll_interval is updated" do
      interval = :rand.uniform(1000)
      :ok = Application.put_env(@app, :blockchain_poll_interval, interval)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_poll_interval)

      assert res == :ok
      assert_received {:called, :set_interval, :poll, interval}
    end

    test "calls the transaction registry's set_listener_interval/1 when blockchain_transaction_poll_interval is updated" do
      interval = :rand.uniform(1000)
      :ok = Application.put_env(@app, :blockchain_transaction_poll_interval, interval)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_transaction_poll_interval)

      assert res == :ok
      assert_received {:called, :set_listener_interval, interval}
    end

    test "calls the transaction registry's set_listener_interval/1 when blockchain_deposit_pooling_interval is updated" do
      interval = :rand.uniform(1000)
      :ok = Application.put_env(@app, :blockchain_deposit_pooling_interval, interval)
      res = BlockchainIntervalSettingsLoader.load(@app, :blockchain_deposit_pooling_interval)

      assert res == :ok
      assert_received {:called, :set_interval, interval}
    end
  end
end
