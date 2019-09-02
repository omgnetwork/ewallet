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

defmodule EthBlockchain.RootchainTransactionListenerTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.RootchainTransactionListener

  describe "broadcast_payload/3" do
    test "returns a success broadcast payload for a valid tx", state do
      assert {:confirmations_count, "valid", 13, 2} ==
               RootchainTransactionListener.broadcast_payload(
                 "valid",
                 state[:adapter_opts][:eth_node_adapter],
                 state[:adapter_opts][:eth_node_adapter_pid]
               )
    end

    test "handles a not found transaction", state do
      assert {:not_found} ==
               RootchainTransactionListener.broadcast_payload(
                 "not_found",
                 state[:adapter_opts][:eth_node_adapter],
                 state[:adapter_opts][:eth_node_adapter_pid]
               )
    end

    test "handles a failed transaction", state do
      assert {:failed_transaction} ==
               RootchainTransactionListener.broadcast_payload(
                 "failed",
                 state[:adapter_opts][:eth_node_adapter],
                 state[:adapter_opts][:eth_node_adapter_pid]
               )
    end
  end
end
