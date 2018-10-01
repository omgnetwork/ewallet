defmodule EWalletAPI.V1.SelfViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletAPI.V1.SelfView

  describe "EWalletAPI.V1.UserView.render/2" do
    test "renders user.json with correct structure" do
      user = build(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          socket_topic: "user:#{user.id}",
          provider_user_id: user.provider_user_id,
          username: user.username,
          full_name: user.full_name,
          display_name: user.display_name,
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
          created_at: nil,
          updated_at: nil,
          encrypted_metadata: %{}
        }
      }

      assert SelfView.render("user.json", %{user: user}) == expected
    end

    test "renders settings.json with correct structure" do
      token1 = build(:token)
      token2 = build(:token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "setting",
          tokens: [
            TokenSerializer.serialize(token1),
            TokenSerializer.serialize(token2)
          ]
        }
      }

      settings = %{tokens: [token1, token2]}
      assert SelfView.render("settings.json", settings) == expected
    end
  end
end
