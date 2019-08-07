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

defmodule EWalletDB.BlockchainWalletTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{BlockchainWallet}
  alias Utils.Helpers.Crypto

  describe "BlockchainWallet factory" do
    test_has_valid_factory(BlockchainWallet)
  end

  describe "get_primary_hot_wallet/1" do
    test "returns the hot wallet for the given blockchain identifier"
  end

  describe "get_all_hot/1" do
    test "returns the list of all hot wallets for the given blockchain identifier"
  end

  describe "get/3" do
    test "returns the blockchain wallet with the given address, type and blockchain identifier"
    test "returns nil if the given address is nil"
  end

  describe "insert/1" do
    test_insert_generate_uuid(BlockchainWallet, :uuid)
    test_insert_generate_timestamps(BlockchainWallet)

    test_insert_field_length(BlockchainWallet, :address)
    test_insert_field_length(BlockchainWallet, :name)
    test_insert_field_length(BlockchainWallet, :public_key)

    test_insert_prevent_duplicate(BlockchainWallet, :address, Crypto.fake_eth_address())
    test_insert_prevent_duplicate(BlockchainWallet, :name, "A name")
    test_insert_prevent_duplicate(BlockchainWallet, :public_key, "0x321")

    test "insert successfuly when type is valid" do
      {res_1, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_hot(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert()

      {res_2, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_cold(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert()

      assert res_1 == :ok
      assert res_2 == :ok
    end

    test "fails to insert when type is invalid" do
      {res, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: "invalid_type", blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert()

      assert res == :error
    end
  end

  describe "insert_hot/1" do
    test "insert successfuly when type is valid" do
      {res, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_hot(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert_hot()

      assert res == :ok
    end

    test "fails to insert when type is invalid" do
      {res, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_cold(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert_hot()

      assert res == :error
    end
  end

  describe "insert_cold/1" do
    test "insert successfuly when type is valid" do
      {res, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_cold(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert_cold()

      assert res == :ok
    end

    test "fails to insert when type is invalid" do
      {res, _wallet} =
        :blockchain_wallet
        |> params_for(%{type: BlockchainWallet.type_hot(), blockchain_identifier: "ethereum"})
        |> BlockchainWallet.insert_cold()

      assert res == :error
    end
  end

  describe "get_by/2" do
    test_schema_get_by_allows_search_by(BlockchainWallet, :address)
    test_schema_get_by_allows_search_by(BlockchainWallet, :name)
    test_schema_get_by_allows_search_by(BlockchainWallet, :public_key)
    test_schema_get_by_allows_search_by(BlockchainWallet, :type)
  end
end
