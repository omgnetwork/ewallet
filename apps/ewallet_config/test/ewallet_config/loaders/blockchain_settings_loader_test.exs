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

defmodule EWalletConfig.BlockchainSettingsLoaderTest do
  # This test cannot be async as it shares the `settings` DB table with others.
  use EWalletConfig.SchemaCase, async: false
  alias EWalletConfig.BlockchainSettingsLoader

  @app :my_app

  defmodule MockTracker do
    @moduledoc """
    Simulates a blockchain tracker without running any business logic.
    """
    use GenServer, restart: :transient

    def start_link(start_opts), do: GenServer.start_link(__MODULE__, [], start_opts)

    def init(_opts), do: {:ok, %{}}
  end

  setup do
    children = [
      Supervisor.child_spec({MockTracker, [name: TrackerOne]}, id: TrackerOne),
      Supervisor.child_spec({MockTracker, [name: TrackerTwo]}, id: TrackerTwo)
    ]

    supervisor = :"blockchain_settings_test_supervisor_#{System.unique_integer()}"
    {:ok, _} = Supervisor.start_link(children, name: supervisor, strategy: :one_for_one)

    {:ok,
     %{
       config_pid: start_supervised!(EWalletConfig.Config),
       supervisor: supervisor,
       trackers: [TrackerOne, TrackerTwo]
     }}
  end

  defp set_blockchain_enabled(enabled?, context) do
    :ok = Application.put_env(@app, :blockchain_enabled, enabled?)
    BlockchainSettingsLoader.load(@app, :blockchain_enabled, context.supervisor, context.trackers)
  end

  describe "load/4" do
    test "stops the running trackers when setting blockchain_enabled:false", context do
      res = set_blockchain_enabled(false, context)

      assert res == :ok
      refute Enum.any?(context.trackers, fn t -> GenServer.whereis(t) end)
    end

    test "starts the trackers when setting blockchain_enabled:true", context do
      # Make sure blockchain_enabled:false initially and the trackers are not running
      :ok = set_blockchain_enabled(false, context)
      refute Enum.any?(context.trackers, fn t -> GenServer.whereis(t) end)

      # Enable blockchain and assert that trackers are running
      res = set_blockchain_enabled(true, context)

      assert res == :ok
      assert Enum.all?(context.trackers, fn t -> t |> GenServer.whereis() |> Process.alive?() end)
    end

    test "does not start the trackers when setting blockchain_enabled:false", context do
      # Make sure blockchain_enabled:false initially and the trackers are not running
      :ok = set_blockchain_enabled(false, context)
      refute Enum.any?(context.trackers, fn t -> GenServer.whereis(t) end)

      # Disable blockchain again and assert that trackers are not running
      res = set_blockchain_enabled(false, context)

      assert res == :ok
      refute Enum.any?(context.trackers, fn t -> GenServer.whereis(t) end)
    end

    test "keeps the trackers running when setting blockchain_enabled:true", context do
      pids = Enum.map(context.trackers, fn tracker -> {tracker, GenServer.whereis(tracker)} end)

      res = set_blockchain_enabled(true, context)

      assert res == :ok
      assert Enum.all?(context.trackers, fn t -> t |> GenServer.whereis() |> Process.alive?() end)
      assert Enum.all?(context.trackers, fn t -> GenServer.whereis(t) == pids[t] end)
    end
  end
end
