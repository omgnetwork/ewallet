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

defmodule EthGethAdapter.TransactionTest do
  use ExUnit.Case, async: true

  describe "send_raw/2" do
    test "submits the raw transaction data and return the response"
    test "returns an error if the transaction data failed to submit"
  end

  describe "get_transaction_count/2" do
    test "returns the total number of transactions on the given address"
  end
end
