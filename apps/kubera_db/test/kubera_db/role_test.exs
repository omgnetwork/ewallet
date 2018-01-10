defmodule KuberaDB.RoleTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.Role

  describe "Role factory" do
    test_has_valid_factory Role
  end

  describe "Role.insert/1" do
    test_insert_generate_uuid Role, :id
    test_insert_generate_timestamps Role
    test_insert_prevent_blank Role, :name
    test_insert_prevent_duplicate Role, :name
  end

  describe "Role.get_by_name/1" do
    test "returns the role record when given an atom" do
      insert(:role, %{name: "some_role"})
      result = Role.get_by_name(:some_role)

      assert result.name == "some_role"
    end

    test "returns the role record when given a string" do
      insert(:role, %{name: "some_role"})
      result = Role.get_by_name("some_role")

      assert result.name == "some_role"
    end

    test "returns nil when the given atom does not match a role" do
      insert(:role, %{name: "some_role"})
      assert Role.get_by_name(:not_admin) == nil
    end
  end

  describe "Role.is_role?/2" do
    test "returns true if the given role atom matches the role's name" do
      role = insert(:role, %{name: "some_role"})
      assert Role.is_role?(role, :some_role)
    end

    test "returns false if the given role atom does not match the role's name" do
      role = insert(:role, %{name: "different_role"})
      refute Role.is_role?(role, :some_role)
    end
  end

  describe "Role.to_atom/1" do
    test "returns role's name as atom" do
      role = insert(:role, %{name: "some_role"})
      assert Role.to_atom(role) == :some_role
    end
  end
end
