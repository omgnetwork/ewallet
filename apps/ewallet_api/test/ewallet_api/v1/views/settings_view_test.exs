defmodule EWalletAPI.V1.SettingsViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.SettingsView

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
            %{
              object: "minted_token",
              id: token1.friendly_id,
              symbol: token1.symbol,
              name: token1.name,
              subunit_to_unit: token1.subunit_to_unit,
              metadata: %{},
              encrypted_metadata: %{}
            },
            %{
              object: "minted_token",
              id: token2.friendly_id,
              symbol: token2.symbol,
              name: token2.name,
              subunit_to_unit: token2.subunit_to_unit,
              metadata: %{},
              encrypted_metadata: %{}
            }]
        }
      }

      settings = %{minted_tokens: [token1, token2]}
      assert SettingsView.render("settings.json", settings) == expected
    end
  end
end
