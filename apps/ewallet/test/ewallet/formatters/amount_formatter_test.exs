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

defmodule EWallet.AmountFormatterTest do
  use ExUnit.Case, async: true
  alias EWallet.AmountFormatter

  describe "format/2" do
    test "formats correctly given an amount and a subunit_to_unit" do
      res = AmountFormatter.format(123, 100)

      assert res == "1.23"
    end

    test "formats correctly given a subunit_to_unit bigger than amount" do
      res = AmountFormatter.format(123, 10_000)

      assert res == "0.0123"
    end

    test "formats correctly given an amount with trailing zeros" do
      res = AmountFormatter.format(1_000_000, 10)

      assert res == "100000"
    end
  end
end
