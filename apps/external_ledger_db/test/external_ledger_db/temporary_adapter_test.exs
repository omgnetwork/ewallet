# Copyright 2018 OmiseGO Pte Ltd
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

defmodule ExternalLedgerDB.TemporaryAdapterTest do
  use ExUnit.Case, async: true
  alias ExternalLedgerDB.TemporaryAdapter

  describe "fetch_token/2" do
    test "returns token data" do
      {res, token} =
        TemporaryAdapter.fetch_token("0x546a574ed633786b6a42f909753c1f7f6f37993a", "ethereum")

      assert res == :ok
      assert Map.has_key?(token, :contract_address)
      assert Map.has_key?(token, :symbol)
      assert Map.has_key?(token, :name)
      assert Map.has_key?(token, :net_version)
      assert Map.has_key?(token, :total_supply)
      assert Map.has_key?(token, :decimals)
    end
  end
end
