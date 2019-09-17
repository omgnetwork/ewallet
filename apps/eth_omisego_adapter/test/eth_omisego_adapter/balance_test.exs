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

defmodule EthOmiseGOAdapter.BalanceTest do
  use EthOmiseGOAdapter.EthOmiseGOAdapterCase, async: true

  alias EthOmiseGOAdapter.Balance

  describe "get/1" do
    test "get and parse balances for an address" do
      {res, data} = Balance.get("valid")
      assert res == :ok

      assert data == %{
               "0x0000000000000000000000000000000000000000" => 100,
               "0x0000000000000000000000000000000000000001" => 1
             }
    end
  end
end
