defmodule AdminAPI.V1.SelfViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.SelfView
  alias EWallet.Web.Date

  describe "render/2" do
    test "renders user.json with correct response structure" do
      user = insert(:user)

      # I prefer to keep this test code duplicate with the `UserView.render/2` test,
      # because in practice they are separate responses.

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          socket_topic: "user:#{user.id}",
          username: user.username,
          provider_user_id: user.provider_user_id,
          email: user.email,
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          metadata: %{
            "first_name" => user.metadata["first_name"],
            "last_name" => user.metadata["last_name"]
          },
          encrypted_metadata: %{},
          created_at: Date.to_iso8601(user.inserted_at),
          updated_at: Date.to_iso8601(user.updated_at)
        }
      }

      assert SelfView.render("user.json", %{user: user}) == expected
    end
  end
end
