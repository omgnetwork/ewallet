defmodule EWalletAPI.V1.SelfViewTest do
  use EWalletAPI.ViewCase, :v1
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
          provider_user_id: user.provider_user_id,
          username: user.username,
          metadata: %{
            "first_name" => user.metadata["first_name"],
            "last_name" => user.metadata["last_name"]
          }
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
            %{
              object: "minted_token",
              id: token1.friendly_id,
              symbol: token1.symbol,
              name: token1.name,
              subunit_to_unit: token1.subunit_to_unit
            },
            %{
              object: "minted_token",
              id: token2.friendly_id,
              symbol: token2.symbol,
              name: token2.name,
              subunit_to_unit: token2.subunit_to_unit
            }]
        }
      }

      settings = %{minted_tokens: [token1, token2]}
      assert SelfView.render("settings.json", settings) == expected
    end
  end
end
