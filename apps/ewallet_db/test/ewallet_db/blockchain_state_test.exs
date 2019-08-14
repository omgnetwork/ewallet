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

defmodule EWalletDB.BlockchainStateTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.BlockchainState

  describe "get/2" do
    test "returns the blockchain state for the given identifier"
    test "returns the blockchain state for the given identifier and queryable"
  end

  describe "insert/1" do
    test "returns the blockchain state inserted with the given attributes"
  end

  describe "update/2" do
    test "returns the blockchain state updated with the given identifier and block number"
    test "returns a :not_found error if the given identifier is not found"
  end
end
