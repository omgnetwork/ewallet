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

defmodule EWalletDB.RoleTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{Membership, Role}
  alias ActivityLogger.System

  describe "Role factory" do
    test_has_valid_factory(Role)
  end

  describe "all/1" do
    test_schema_all_returns_all_records(Role, 10)
  end

  describe "get/2" do
    test_schema_get_returns_struct_if_given_valid_id(Role)
    test_schema_get_returns_nil_for_id(Role, "rol_00000000000000000000000000")
    test_schema_get_returns_nil_for_id(Role, "not_an_id")
    test_schema_get_accepts_preload(Role, :users)
  end

  describe "get_by/1" do
    test_schema_get_by_allows_search_by(Role, :name)
    test_schema_get_by_allows_search_by(Role, :display_name)
  end

  describe "insert/1" do
    test_insert_ok(Role, :name, "test_role_name")
    test_insert_generate_uuid(Role, :uuid)
    test_insert_generate_external_id(Role, :id, "rol_")
    test_insert_generate_timestamps(Role)

    test_insert_prevent_blank(Role, :name)
    test_insert_prevent_duplicate(Role, :name)
  end

  describe "update/1" do
    test_update_field_ok(Role, :name)
    test_update_field_ok(Role, :display_name)
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(Role)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(Role)

    test "returns :role_not_empty error if the role has associated users" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "test_role_not_empty")
      {:ok, _membership} = Membership.assign(user, account, role, %System{})

      users = role.id |> Role.get(preload: :users) |> Map.get(:users)
      assert Enum.count(users) > 0

      {res, code} = Role.delete(role, %System{})

      assert res == :error
      assert code == :role_not_empty
      refute role.id |> Role.get() |> Role.deleted?()
    end
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(Role)
  end

  describe "is_role?/2" do
    test "returns true if the given string matches the role's name" do
      role = insert(:role, %{name: "some_role"})
      assert Role.is_role?(role, "some_role")
    end

    test "returns false if the given string does not match the role's name" do
      role = insert(:role, %{name: "some_role"})
      refute Role.is_role?(role, "different_role")
    end
  end
end
