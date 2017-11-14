defmodule KuberaAPI.V1.SettingsViewTest do
  use KuberaAPI.ViewCase, :v1
  alias KuberaAPI.V1.SettingsView

  describe "KuberaAPI.V1.SettingsView" do

    test "render/2 with settings.json" do
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
              symbol: token1.symbol,
              name: token1.name,
              subunit_to_unit: token1.subunit_to_unit
            },
            %{
              object: "minted_token",
              symbol: token2.symbol,
              name: token2.name,
              subunit_to_unit: token2.subunit_to_unit
            }]
        }
      }

      settings = %{minted_tokens: [token1, token2]}
      assert SettingsView.render("settings.json", settings) == expected
    end
  end
end
