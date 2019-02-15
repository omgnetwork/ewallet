# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule Utils.Helpers.UnitTest do
  use ExUnit.Case, async: true
  alias Utils.Helpers.Unit

  describe "decimals_to_subunit/1" do
    test "returns the subunit for the given decimals" do
      assert Unit.decimals_to_subunit(0) == 1
      assert Unit.decimals_to_subunit(1) == 10
      assert Unit.decimals_to_subunit(2) == 100
      assert Unit.decimals_to_subunit(3) == 1_000
      assert Unit.decimals_to_subunit(4) == 10_000
      assert Unit.decimals_to_subunit(5) == 100_000
      assert Unit.decimals_to_subunit(6) == 1_000_000
      assert Unit.decimals_to_subunit(7) == 10_000_000
      assert Unit.decimals_to_subunit(8) == 100_000_000
      assert Unit.decimals_to_subunit(9) == 1_000_000_000

      assert Unit.decimals_to_subunit(10) == 10_000_000_000
      assert Unit.decimals_to_subunit(11) == 100_000_000_000
      assert Unit.decimals_to_subunit(12) == 1_000_000_000_000
      assert Unit.decimals_to_subunit(13) == 10_000_000_000_000
      assert Unit.decimals_to_subunit(14) == 100_000_000_000_000
      assert Unit.decimals_to_subunit(15) == 1_000_000_000_000_000
      assert Unit.decimals_to_subunit(16) == 10_000_000_000_000_000
      assert Unit.decimals_to_subunit(17) == 100_000_000_000_000_000
      assert Unit.decimals_to_subunit(18) == 1_000_000_000_000_000_000
    end
  end
end
