defmodule EWalletDB.RoleTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Role

  describe "Role factory" do
    test_has_valid_factory Role
  end

  describe "Role.insert/1" do
    test_insert_generate_uuid Role, :uuid
    test_insert_generate_timestamps Role
    test_insert_prevent_blank Role, :name
    test_insert_prevent_duplicate Role, :name
  end

  describe "Role.get_by_name/1" do
    test "returns the role record when given a string" do
      insert(:role, %{name: "some_role"})
      result = Role.get_by_name("some_role")

      assert result.name == "some_role"
    end

    test "returns nil when the given string does not match a role" do
      insert(:role, %{name: "some_role"})
      assert Role.get_by_name(:not_admin) == nil
    end
  end

  describe "Role.is_role?/2" do
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
