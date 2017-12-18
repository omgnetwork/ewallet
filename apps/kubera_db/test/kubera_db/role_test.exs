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

  describe "Role.is_role?/2" do
    test "returns true if the given role atom matches the role's name" do
      role = insert(:role, %{name: "admin"})
      assert Role.is_role?(role, :admin)
    end

    test "returns false if the given role atom does not match the role's name" do
      role = insert(:role, %{name: "not_admin"})
      refute Role.is_role?(role, :admin)
    end
  end
end
