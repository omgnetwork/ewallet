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

defmodule EthGethAdapter.WorkerTest do
  use ExUnit.Case, async: true

  describe "handle_call/3" do
    test "handles :get_balances calls"
    test "handles :send_raw calls"
    test "handles :get_transaction_count calls"
    test "handles :get_transaction_receipt calls"
    test "handles :get_block_number calls"
    test "handles :get_block calls"
    test "handles :get_field calls"
    test "handles :get_errors calls"
  end
end
