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

defmodule EWallet.Web.V1.MembershipSerializerTest do
  use EWallet.Web.SerializerCase, :v1

  alias EWallet.Web.V1.{
    MembershipSerializer,
    AdminUserSerializer,
    KeySerializer,
    AccountSerializer
  }

  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Orchestrator, Paginator, V1.MembershipOverlay}
  alias EWalletDB.{User, Membership, Key}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  describe "serialize/1" do
    test "serializes a user membership correctly" do
      account = :account |> insert() |> Repo.preload(:categories)
      {:ok, user} = :admin |> params_for() |> User.insert()
      role = insert(:role)
      {:ok, membership} = Membership.assign(user, account, role, %System{})
      {:ok, membership} = Orchestrator.one(membership, MembershipOverlay)

      expected = %{
        object: "membership",
        user_id: user.id,
        user: AdminUserSerializer.serialize(user),
        key_id: nil,
        key: nil,
        account_id: account.id,
        account: AccountSerializer.serialize(account),
        role: role.name,
        created_at: DateFormatter.to_iso8601(membership.inserted_at),
        updated_at: DateFormatter.to_iso8601(membership.updated_at)
      }

      assert MembershipSerializer.serialize(membership) == expected
    end

    test "serializes a key membership correctly" do
      account = :account |> insert() |> Repo.preload(:categories)
      {:ok, key} = :key |> params_for() |> Key.insert()
      key = Key.get(key.id)

      role = insert(:role)
      {:ok, membership} = Membership.assign(key, account, role, %System{})
      {:ok, membership} = Orchestrator.one(membership, MembershipOverlay)

      expected = %{
        object: "membership",
        user_id: nil,
        user: nil,
        key_id: key.id,
        key: KeySerializer.serialize(key),
        account_id: account.id,
        account: AccountSerializer.serialize(account),
        role: role.name,
        created_at: DateFormatter.to_iso8601(membership.inserted_at),
        updated_at: DateFormatter.to_iso8601(membership.updated_at)
      }

      assert MembershipSerializer.serialize(membership) == expected
    end

    test "serializes a user membership paginator into a paginated list of user memberships correctly" do
      account = :account |> insert() |> Repo.preload(:categories)
      role = insert(:role)

      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      {:ok, membership_1} = Membership.assign(user_1, account, role, %System{})
      {:ok, membership_1} = Orchestrator.one(membership_1, MembershipOverlay)

      {:ok, membership_2} = Membership.assign(user_2, account, role, %System{})
      {:ok, membership_2} = Orchestrator.one(membership_2, MembershipOverlay)

      paginator = %Paginator{
        data: [membership_1, membership_2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "membership",
            user_id: user_1.id,
            user: AdminUserSerializer.serialize(user_1),
            key_id: nil,
            key: nil,
            account_id: account.id,
            account: AccountSerializer.serialize(account),
            role: role.name,
            created_at: DateFormatter.to_iso8601(membership_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(membership_1.updated_at)
          },
          %{
            object: "membership",
            user_id: user_2.id,
            user: AdminUserSerializer.serialize(user_2),
            key_id: nil,
            key: nil,
            account_id: account.id,
            account: AccountSerializer.serialize(account),
            role: role.name,
            created_at: DateFormatter.to_iso8601(membership_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(membership_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert MembershipSerializer.serialize(paginator) == expected
    end

    test "serializes a key membership paginator into a paginated list of key memberships correctly" do
      account = :account |> insert() |> Repo.preload(:categories)
      role = insert(:role)

      key_1 = insert(:key)
      key_1 = Key.get(key_1.id)

      key_2 = insert(:key)
      key_2 = Key.get(key_2.id)

      {:ok, membership_1} = Membership.assign(key_1, account, role, %System{})
      {:ok, membership_1} = Orchestrator.one(membership_1, MembershipOverlay)

      {:ok, membership_2} = Membership.assign(key_2, account, role, %System{})
      {:ok, membership_2} = Orchestrator.one(membership_2, MembershipOverlay)

      paginator = %Paginator{
        data: [membership_1, membership_2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "membership",
            user_id: nil,
            user: nil,
            key_id: key_1.id,
            key: KeySerializer.serialize(key_1),
            account_id: account.id,
            account: AccountSerializer.serialize(account),
            role: role.name,
            created_at: DateFormatter.to_iso8601(membership_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(membership_1.updated_at)
          },
          %{
            object: "membership",
            user_id: nil,
            user: nil,
            key_id: key_2.id,
            key: KeySerializer.serialize(key_2),
            account_id: account.id,
            account: AccountSerializer.serialize(account),
            role: role.name,
            created_at: DateFormatter.to_iso8601(membership_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(membership_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert MembershipSerializer.serialize(paginator) == expected
    end

    test "serializes to nil if membership is not given" do
      assert MembershipSerializer.serialize(nil) == nil
    end

    test "serializes to nil if membership is not loaded" do
      assert MembershipSerializer.serialize(%NotLoaded{}) == nil
    end
  end
end
