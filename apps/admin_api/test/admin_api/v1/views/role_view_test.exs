defmodule AdminAPI.V1.RoleViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.RoleView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.RoleSerializer

  describe "render/2" do
    test "renders role.json with correct response structure" do
      role = insert(:role)

      expected = %{
        version: @expected_version,
        success: true,
        data: RoleSerializer.serialize(role)
      }

      assert RoleView.render("role.json", %{role: role}) == expected
    end

    test "renders roles.json with correct response structure" do
      role1 = insert(:role)
      role2 = insert(:role)

      paginator = %Paginator{
        data: [role1, role2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: RoleSerializer.serialize(paginator)
      }

      assert RoleView.render("roles.json", %{roles: paginator}) == expected
    end
  end
end
