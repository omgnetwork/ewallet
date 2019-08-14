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

defmodule EthBlockchain.TransactionReceiptTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.TransactionReceipt

  describe "get/3" do
    test "gets a transaction receipt", state do
      receipt = TransactionReceipt.get(%{tx_hash: "fu"}, :dumb, state[:pid])
      assert {:ok, :success, _} = receipt
    end
  end
end
