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

defmodule EWalletDB.BlockchainDepositWalletTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.BlockchainDepositWallet

  describe "all/1" do
    test "returns the list of all blockchain deposit wallets"
  end

  describe "get/2" do
    test "returns the blockchain deposit wallet by the given address"
  end

  describe "get_last_for/1" do
    test "returns the latest-generated blockchain deposit wallet for the given wallet"
  end

  describe "get_by/2" do
    test "returns the blockchain deposit wallet by the given fields"
  end

  describe "insert/1" do
    test "returns the blockchain deposit wallet inserted with the given attributes"
  end
end
