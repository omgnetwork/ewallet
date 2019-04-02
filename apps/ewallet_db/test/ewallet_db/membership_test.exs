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

defmodule EWalletDB.MembershipTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{Membership, Repo, User}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  describe "Membership factory" do
    # Not using `test_has_valid_factory/1` macro here because `Membership.insert/1` is private.
    # So we need to do `Repo.insert/1` directly to test the factory.
    test "produces valid params and inserts successfully" do
      {res, membership} = :membership |> build() |> Repo.insert()

      assert res == :ok
      assert %Membership{} = membership
    end
  end

  describe "Membership.get_by_member_and_account/2" do
    test "returns a list of memberships associated with the given user and account" do
      admin = insert(:admin)
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      membership = insert(:membership, %{user: admin, account: account, role: role})

      result = Membership.get_by_member_and_account(admin, account)

      assert result.uuid == membership.uuid
    end

    test "returns a list of memberships associated with the given key and account" do
      key = insert(:key)
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      membership = insert(:membership, %{key: key, account: account, role: role})
      result = Membership.get_by_member_and_account(key, account)

      assert result.uuid == membership.uuid
    end
  end

  describe "Membership.query_all_by_user/1" do
    test "returns all memberships associated with the given user" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)

      role = insert(:role, %{name: "some_role"})

      account_1 = insert(:account)
      account_2 = insert(:account)

      membership_1 = insert(:membership, %{user: admin_1, account: account_1, role: role})
      membership_2 = insert(:membership, %{user: admin_1, account: account_2, role: role})
      membership_3 = insert(:membership, %{user: admin_2, account: account_2, role: role})

      membership_uuids =
        admin_1 |> Membership.query_all_by_user() |> Repo.all() |> UUID.get_uuids()

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, membership_1.uuid)
      assert Enum.member?(membership_uuids, membership_2.uuid)
      refute Enum.member?(membership_uuids, membership_3.uuid)
    end
  end

  describe "Membership.query_all_by_key/3" do
    test "returns all memberships associated with the given key" do
      account_1 = insert(:account)
      account_2 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)

      role = insert(:role, %{name: "some_role"})

      membership_1 = insert(:membership, %{key: key_1, account: account_1, role: role})
      membership_2 = insert(:membership, %{key: key_1, account: account_2, role: role})
      membership_3 = insert(:membership, %{key: key_2, account: account_2, role: role})

      membership_uuids = key_1 |> Membership.query_all_by_key() |> Repo.all() |> UUID.get_uuids()

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, membership_1.uuid)
      assert Enum.member?(membership_uuids, membership_2.uuid)
      refute Enum.member?(membership_uuids, membership_3.uuid)
    end
  end

  describe "Membership.assign/3" do
    test "returns {:ok, membership} on successful assignment" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})

      {res, membership} = Membership.assign(user, account, "some_role", %System{})

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == account.uuid
      assert membership.role_uuid == role.uuid
    end

    test "re-assigns user to the new role if the user has an existing role on the account" do
      user = insert(:user)
      account = insert(:account)

      insert(:role, %{name: "old_role"})
      insert(:role, %{name: "new_role"})

      {:ok, _membership} = Membership.assign(user, account, "old_role", %System{})
      {:ok, _membership} = Membership.assign(user, account, "new_role", %System{})

      user = Repo.preload(user, :roles, force: true)
      assert User.get_roles(user) == ["new_role"]
    end

    test "returns {:error, :role_not_found} if the given role does not exist" do
      user = insert(:user)
      account = insert(:account)

      {res, reason} = Membership.assign(user, account, "missing_role", %System{})
      assert res == :error
      assert reason == :role_not_found
    end
  end

  describe "Membership.unassign/2" do
    test "returns {:ok, membership} when unassigned successfully" do
      {user, account} = insert_user_with_role("some_role")
      assert User.get_roles(user) == ["some_role"]

      {:ok, _} = Membership.unassign(user, account, %System{})
      assert User.get_roles(user) == []
    end

    test "returns {:error, :membership_not_found} if the user is not assigned to the account" do
      user = insert(:user)
      account = insert(:account)

      assert Membership.unassign(user, account, %System{}) == {:error, :membership_not_found}
    end
  end
end
