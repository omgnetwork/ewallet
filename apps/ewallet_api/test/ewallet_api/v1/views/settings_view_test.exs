defmodule EWalletAPI.V1.SettingsViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletAPI.V1.SettingsView

  describe "EWalletAPI.V1.SettingsView.render/2" do
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
      assert SettingsView.render("settings.json", settings) == expected
    end
  end
end
