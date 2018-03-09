defmodule EWalletAPI.V1.SettingsSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletAPI.V1.SettingsSerializer

  describe "V1.SettingsSerializer" do
    test "serialized data contains a list of minted_tokens" do
      settings = %{minted_tokens: build_list(3, :minted_token)}
      serialized = SettingsSerializer.serialize(settings)

      assert serialized.object == "setting"
      assert Map.has_key?(serialized, :minted_tokens)
      assert is_list(serialized.minted_tokens)
      assert length(serialized.minted_tokens) == 3
    end
  end
end
