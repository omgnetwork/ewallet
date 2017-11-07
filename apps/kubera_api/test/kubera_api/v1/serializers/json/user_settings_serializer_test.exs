defmodule KuberaAPI.V1.UserSettingsSerializerTest do
  use KuberaAPI.SerializerCase, :v1
  alias KuberaAPI.V1.JSON.UserSettingsSerializer

  describe "V1.JSON.UserSettingsSerializer" do
    test "serialized data contains a list of minted_tokens" do
      settings = %{minted_tokens: build_list(3, :minted_token)}
      serialized = UserSettingsSerializer.serialize(settings)

      assert serialized.object == "setting"
      assert Map.has_key?(serialized, :minted_tokens)
      assert is_list(serialized.minted_tokens)
      assert length(serialized.minted_tokens) == 3
    end
  end
end
