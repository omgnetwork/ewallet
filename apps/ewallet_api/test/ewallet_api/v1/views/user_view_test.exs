defmodule EWalletAPI.V1.UserViewTest do
  use EWalletAPI.ViewCase, :v1
  alias Ecto.UUID
  alias EWalletAPI.V1.UserView
  alias EWalletDB.User

  describe "EWalletAPI.V1.UserView.render/2" do
    test "renders user.json with correct structure" do
      user = %User{
        id: UUID.generate(),
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
          socket_topic: "user:#{user.id}",
          provider_user_id: user.provider_user_id,
          username: user.username,
          email: user.email,
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          metadata: %{
            first_name: "John",
            last_name: "Doe"
          },
          created_at: nil,
          updated_at: nil,
          encrypted_metadata: %{}
        }
      }

      assert render(UserView, "user.json", user: user) == expected
    end
  end
end
