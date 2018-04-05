defmodule EWalletAPI.V1.SelfViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.SelfView
  alias EWallet.Web.V1.MintedTokenSerializer

  describe "EWalletAPI.V1.UserView.render/2" do
    test "renders user.json with correct structure" do
      user = build(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          external_id: user.external_id,
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
      token1 = build(:minted_token)
      token2 = build(:minted_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "setting",
          minted_tokens: [
            MintedTokenSerializer.serialize(token1),
            MintedTokenSerializer.serialize(token2),
          ]
        }
      }

      settings = %{minted_tokens: [token1, token2]}
      assert SelfView.render("settings.json", settings) == expected
    end
  end
end
