defmodule KuberaAdmin.V1.SelfViewTest do
  use KuberaAdmin.ViewCase, :v1
  alias KuberaAdmin.V1.SelfView
  alias Ecto.UUID

  describe "render/2" do
    test "renders user.json with correct structure" do
      user = %{
        id: UUID.generate(),
        username: "johndoe",
        provider_user_id: "provider_id_1234",
        email: "example@omise.co",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      result = SelfView.render("user.json", %{user: user})

      assert result.success == true
      assert is_map(result.data)
      assert result.data.object == "user"
    end
  end
end
