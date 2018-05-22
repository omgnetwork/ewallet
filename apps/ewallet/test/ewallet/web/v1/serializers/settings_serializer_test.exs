defmodule EWallet.Web.V1.SettingsSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.SettingsSerializer

  describe "V1.SettingsSerializer" do
    test "serialized data contains a list of tokens" do
      settings = %{tokens: build_list(3, :token)}
      serialized = SettingsSerializer.serialize(settings)

      assert serialized.object == "setting"
      assert Map.has_key?(serialized, :tokens)
      assert is_list(serialized.tokens)
      assert length(serialized.tokens) == 3
    end
  end
end
