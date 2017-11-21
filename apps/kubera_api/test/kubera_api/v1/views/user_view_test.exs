defmodule KuberaAPI.V1.UserViewTest do
  use KuberaAPI.ViewCase, :v1
  alias KuberaAPI.V1.UserView
  alias KuberaDB.User
  alias Ecto.UUID

  describe "KuberaAPI.V1.UserView.render/2" do
    test "renders user.json with correct structure" do
      user = %User{
        id: UUID.generate,
        username: "johndoe",
        provider_user_id: "provider_id_9999",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          provider_user_id: user.provider_user_id,
          username: user.username,
          metadata: %{
            first_name: user.metadata.first_name,
            last_name: user.metadata.last_name
          }
        }
      }

      assert render(UserView, "user.json", user: user) == expected
    end
  end
end
