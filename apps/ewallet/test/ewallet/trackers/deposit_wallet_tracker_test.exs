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

defmodule EWallet.DepositWalletTrackerTest do
  use EWallet.DBCase, async: false
  alias EWallet.DepositWalletTracker

  describe "start_link/1" do
    test "starts a deposit wallet tracker" do
      opts = [
        name: :test_deposit_wallet_tracker_start_link,
        attrs: %{blockchain_identifier: "dumb"}
      ]

      assert {:ok, pid} = DepositWalletTracker.start_link(opts)
      assert Process.alive?(pid)
      assert GenServer.stop(pid) == :ok
    end
  end
end
