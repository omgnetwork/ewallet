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

defmodule EWalletDB.BlockchainHDWalletTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.BlockchainHDWallet

  describe "get_primary/1" do
    test "returns an HD wallet" do
      _ = insert(:blockchain_hd_wallet)
      assert %BlockchainHDWallet{} = BlockchainHDWallet.get_primary()
    end
  end

  describe "insert/1" do
    test "returns the HD wallet inserted with the given attributes" do
      attrs = %{
        blockchain_identifier: "dumb",
        keychain_uuid: "test_keychain_uuid",
        originator: %System{}
      }

      {res, wallet} = BlockchainHDWallet.insert(attrs)

      assert res == :ok
      assert wallet.blockchain_identifier == attrs.blockchain_identifier
      assert wallet.keychain_uuid == attrs.keychain_uuid
    end

    test "returns :blockchain_hd_wallet_already_exists if an HD wallet already exists" do
      _ = insert(:blockchain_hd_wallet)

      attrs = %{
        blockchain_identifier: "dumb",
        keychain_uuid: "test_keychain_uuid_exists"
      }

      {res, error} = BlockchainHDWallet.insert(attrs)

      assert res == :error
      assert error == :blockchain_hd_wallet_already_exists
    end
  end
end
