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

defmodule EWallet.DepositWalletPoolingTrackerTest do
  use EWallet.DBCase, async: false
  alias EWallet.DepositWalletPoolingTracker

  setup do
    opts = [
      name: :"#{__MODULE__}-tracker-test-#{System.unique_integer()}",
      blockchain_identifier: "some_blockchain_identifier"
    ]

    {:ok, pid} = DepositWalletPoolingTracker.start_link(opts)

    {:ok, %{
      start_opts: opts,
      pid: pid
    }}
  end

  describe "start_link/1" do
    test "starts a deposit wallet tracker", context do
      :ok = GenServer.stop(context.pid)

      {res, pid} = DepositWalletPoolingTracker.start_link(context.start_opts)

      assert res == :ok
      assert Process.alive?(pid)

      :ok = GenServer.stop(pid)
    end
  end

  describe "set_interval/2" do
    test "sets the polling_interval", context do
      interval = :rand.uniform(100_000)

      assert DepositWalletPoolingTracker.set_interval(interval, context.pid) == :ok
      assert :sys.get_state(context.pid)[:pooling_interval] == interval

      :ok = GenServer.stop(context.pid)
    end

    test "resets the timer", context do
      timer = :sys.get_state(context.pid)[:timer]

      interval = :rand.uniform(100_000)
      :ok = DepositWalletPoolingTracker.set_interval(interval, context.pid)

      refute :sys.get_state(context.pid)[:timer] == timer
      assert GenServer.stop(context.pid) == :ok
    end
  end
end
