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

defmodule EthBlockchain.StatusTest do
  use EthBlockchain.EthBlockchainCase, async: true
  alias EthBlockchain.Status

  describe "get_status/0" do
    test "returns the overall Ethereum connectivity status" do
      assert Status.get_status() ==
               {:ok,
                %{
                  eth_syncing: false,
                  client_version: "DumbAdapter/v4.2.0-c999068/linux/go1.9.2",
                  network_id: "99",
                  last_seen_eth_block_number: 14,
                  peer_count: 42
                }}
    end
  end
end
