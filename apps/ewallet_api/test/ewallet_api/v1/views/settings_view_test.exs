defmodule EWalletAPI.V1.SettingsViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.SettingsView
  alias EWallet.Web.V1.MintedTokenSerializer

  describe "EWalletAPI.V1.SettingsView.render/2" do
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
            MintedTokenSerializer.serialize(token2)
          ]
        }
      }

      settings = %{minted_tokens: [token1, token2]}
      assert SettingsView.render("settings.json", settings) == expected
    end
  end
end
