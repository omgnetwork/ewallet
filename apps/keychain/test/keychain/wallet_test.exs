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

defmodule Keychain.WalletTest do
  use Keychain.DBCase
  alias Keychain.{Key, Repo, Wallet}

  describe "generate/1" do
    test "generates a ECDH keypair and wallet id" do
      assert Repo.aggregate(Key, :count, :wallet_id) == 0
      {:ok, {wallet_id, public_key}} = Wallet.generate()
      {:ok, {_, _}} = Wallet.generate()
      {:ok, {_, _}} = Wallet.generate()
      {:ok, {_, _}} = Wallet.generate()
      assert Repo.aggregate(Key, :count, :wallet_id) == 4

      assert is_binary(wallet_id)
      assert byte_size(wallet_id) == 42

      assert is_binary(public_key)
      assert byte_size(public_key) == 130
    end
  end
end
