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

defmodule Keychain.KeyTest do
  use ExUnit.Case
  import Keychain.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias Keychain.{Repo, Key}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "private_key_for_wallet_address/1" do
    test "retrieves a private key for wallet" do
      key_1 = insert(:key)
      key_2 = insert(:key)

      assert Key.private_key_for_wallet_address(key_1.wallet_address) == key_1.private_key
      assert Key.private_key_for_wallet_address(key_2.wallet_address) == key_2.private_key
    end

    test "returns nil for non-existing wallet" do
      assert Key.private_key_for_wallet_address("nonexists") == nil
    end
  end

  describe "private_key_for_uuid/1" do
    test "returns the private key for the given wallet uuid" do
      key_1 = insert(:key)
      key_2 = insert(:key)

      assert Key.private_key_for_uuid(key_1.uuid) == key_1.private_key
      assert Key.private_key_for_uuid(key_2.uuid) == key_2.private_key
    end
  end

  describe "public_key_for_uuid/1" do
    test "returns the public key for the given wallet uuid" do
      key_1 = insert(:key)
      key_2 = insert(:key)

      assert Key.public_key_for_uuid(key_1.uuid) == key_1.public_key
      assert Key.public_key_for_uuid(key_2.uuid) == key_2.public_key
    end
  end

  describe "insert/1" do
    test "inserts a new private key" do
      assert Repo.all(Key) == []

      {:ok, key} =
        Key.insert(%{
          wallet_address: "address-1",
          private_key: "private-key-1",
          public_key: "public-key-1"
        })

      assert Repo.all(Key) == [key]
    end

    test "raises if wallet address already exists" do
      key_1 = insert(:key)

      {res, changeset} =
        Key.insert(%{
          wallet_address: key_1.wallet_address,
          private_key: "private-key-1",
          public_key: "public-key-1"
        })

      assert res == :error
      refute changeset.valid?

      assert changeset.errors == [
               wallet_address: {
                 "has already been taken",
                 [constraint: :unique, constraint_name: "keychain_wallet_address_index"]
               }
             ]
    end
  end
end
