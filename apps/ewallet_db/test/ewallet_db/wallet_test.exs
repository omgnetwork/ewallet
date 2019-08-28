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

defmodule EWalletDB.WalletTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias Ecto.UUID
  alias Utils.Types.WalletAddress
  alias EWalletDB.{Account, User, Wallet}

  describe "Wallet factory" do
    test_has_valid_factory(Wallet)
    test_encrypted_map_field(Wallet, "wallet", :encrypted_metadata)
  end

  describe "insert/1" do
    test_insert_generate_uuid(Wallet, :uuid)
    test_insert_generate_timestamps(Wallet)

    test_insert_field_length(Wallet, :name)

    test_insert_field_length(
      Wallet,
      :identifier,
      "secondary_A long long long long long long long long long long long long
    long long long long long long long long long long long long long long long
    long long long long long long long long long long long long long long long
    long long long long long long long long long long long long long value"
    )

    test "populates the schema with a valid wallet address" do
      {:ok, wallet} =
        :wallet
        |> params_for(address: nil)
        |> Wallet.insert()

      assert String.match?(wallet.address, ~r/^[a-z]{4}[0-9]{12}$/)
    end

    test "uses the given wallet address if provided" do
      {:ok, wallet} =
        :wallet
        |> params_for(address: "test-1234-5678-9012")
        |> Wallet.insert()

      assert wallet.address == "test123456789012"
    end

    test_insert_ok(Wallet, :address, "abcd999999999999")

    test_insert_prevent_all_blank(Wallet, [:account, :user])
    test_insert_prevent_duplicate(Wallet, :address, "aaaa123456789012")
    test_default_metadata_fields(Wallet, "wallet")

    test "allows insert if provided a user without account_uuid" do
      {res, _wallet} =
        :wallet
        |> params_for(%{user: insert(:user), account_uuid: nil})
        |> Wallet.insert()

      assert res == :ok
    end

    test "allows insert if provided an account without user" do
      {res, _wallet} =
        :wallet
        |> params_for(%{account: insert(:account), user: nil})
        |> Wallet.insert()

      assert res == :ok
    end

    test "allows insert if name == genesis" do
      {res, _wallet} =
        :wallet
        |> params_for(%{account: nil, user: nil, identifier: Wallet.genesis()})
        |> Wallet.insert()

      assert res == :ok
    end

    test "prevents creation of a wallet with both a user and account" do
      params = %{user: insert(:user), account: insert(:account)}
      {result, changeset} = :wallet |> params_for(params) |> Wallet.insert()

      assert result == :error

      assert changeset.errors ==
               [
                 {%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
                  {"only one must be present", [validation: :only_one_required]}}
               ]
    end

    test "prevents creation of a wallet without a user and an account" do
      params = %{user: nil, account: nil}
      {result, changeset} = :wallet |> params_for(params) |> Wallet.insert()

      assert result == :error

      assert changeset.errors ==
               [
                 {%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
                  {"can't all be blank", [validation: :required_exclusive]}}
               ]
    end

    test "allows insert of a wallet with the same name than one for another account" do
      {:ok, account1} = :account |> params_for() |> Account.insert()
      {:ok, account2} = :account |> params_for() |> Account.insert()
      wallet1 = Account.get_primary_wallet(account1)
      wallet2 = Account.get_primary_wallet(account2)

      assert wallet1.name == wallet2.name
    end

    test "allows insert of a wallet with the same name than one for another user" do
      {:ok, user1} = :user |> params_for() |> User.insert()
      {:ok, user2} = :user |> params_for() |> User.insert()
      wallet1 = User.get_primary_wallet(user1)
      wallet2 = User.get_primary_wallet(user2)

      assert wallet1.name == wallet2.name
    end

    test "prevents creation of a wallet with the same name for the same account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {res, changeset} = Account.insert_wallet(account, wallet.name)

      assert res == :error

      assert changeset.errors == [
               unique_account_name:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "wallet_account_uuid_name_index"]}
             ]
    end

    test "prevents creation of a wallet with the same name for the same user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      {res, changeset} = User.insert_wallet(user, wallet.name)

      assert res == :error

      assert changeset.errors == [
               unique_user_name:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "wallet_user_uuid_name_index"]}
             ]
    end
  end

  describe "insert_secondary_or_burn/1" do
    test "returns the secondary wallet inserted with the given attributes" do
      {res, wallet} =
        :wallet
        |> string_params_for(account: insert(:account), user: nil, identifier: Wallet.secondary())
        |> Map.put("originator", %System{})
        |> Wallet.insert_secondary_or_burn()

      assert res == :ok
      assert String.starts_with?(wallet.identifier, "#{Wallet.secondary()}_")
    end

    test "returns the burn wallet inserted with the given attributes" do
      {res, wallet} =
        :wallet
        |> string_params_for(account: insert(:account), user: nil, identifier: Wallet.burn())
        |> Map.put("originator", %System{})
        |> Wallet.insert_secondary_or_burn()

      assert res == :ok
      assert String.starts_with?(wallet.identifier, "#{Wallet.burn()}_")
    end
  end

  describe "get/1" do
    test "returns an existing wallet using an address" do
      {:ok, inserted} =
        :wallet
        |> params_for()
        |> Wallet.insert()

      wallet = Wallet.get(inserted.address)
      assert wallet.address == inserted.address
    end

    test "returns nil if the wallet address does not exist" do
      {:ok, address} = WalletAddress.generate()
      assert Wallet.get(address) == nil
    end

    test "returns nil if the wallet address is a UUID" do
      wallet = insert(:wallet, address: UUID.generate())
      assert Wallet.get(wallet.address).uuid == wallet.uuid
    end

    test "returns nil if the wallet address is not valid" do
      assert Wallet.get("something") == nil
    end
  end

  describe "get_genesis/0" do
    test "inserts the genesis address if not existing" do
      assert Wallet.get("gnis000000000000") == nil
      genesis = Wallet.get_genesis()
      assert Wallet.get("gnis000000000000") == genesis
    end

    test "returns the existing genesis address if present" do
      inserted_genesis = Wallet.get_genesis()
      genesis = Wallet.get_genesis()
      assert inserted_genesis == genesis
    end
  end

  describe "insert_genesis/0" do
    test "returns the inserted genesis wallet" do
      {res, wallet} = Wallet.insert_genesis()

      assert res == :ok
      assert wallet.identifier == Wallet.genesis()
    end
  end

  describe "burn_wallet?/1" do
    test "returns true if the given wallet is a burn wallet" do
      {:ok, wallet} =
        :wallet
        |> string_params_for(account: insert(:account), user: nil, identifier: Wallet.burn())
        |> Map.put("originator", %System{})
        |> Wallet.insert_secondary_or_burn()

      assert Wallet.burn_wallet?(wallet)
    end

    test "returns false if the given wallet is not a burn wallet" do
      {:ok, wallet} =
        :wallet
        |> string_params_for(%{
          account: insert(:account),
          user: nil,
          identifier: Wallet.secondary()
        })
        |> Map.put("originator", %System{})
        |> Wallet.insert_secondary_or_burn()

      refute Wallet.burn_wallet?(wallet)
    end

    test "returns false if given nil" do
      refute Wallet.burn_wallet?(nil)
    end
  end

  describe "enable_or_disable/2" do
    test "returns :primary_wallet_cannot_be_disabled if the given wallet is a primary wallet" do
      {:ok, wallet} =
        :wallet
        |> params_for(identifier: Wallet.primary())
        |> Wallet.insert()

      {res, error} = Wallet.enable_or_disable(wallet, %{enabled: false, originator: %System{}})

      assert res == :error
      assert error == :primary_wallet_cannot_be_disabled
    end

    test "returns the enabled wallet if given enabled:true" do
      {:ok, wallet} =
        :wallet
        |> params_for(account: insert(:account), user: nil, identifier: "#{Wallet.secondary()}_1")
        |> Wallet.insert()

      {res, wallet} = Wallet.enable_or_disable(wallet, %{enabled: true, originator: %System{}})

      assert res == :ok
      assert wallet.enabled
    end

    test "returns the disabled wallet if given enabled:false" do
      {:ok, wallet} =
        :wallet
        |> params_for(account: insert(:account), user: nil, identifier: "#{Wallet.secondary()}_1")
        |> Wallet.insert()

      {res, wallet} = Wallet.enable_or_disable(wallet, %{enabled: false, originator: %System{}})

      assert res == :ok
      refute wallet.enabled
    end
  end
end
