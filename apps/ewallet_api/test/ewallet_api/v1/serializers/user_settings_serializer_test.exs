defmodule EWalletAPI.V1.UserSettingsSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletAPI.V1.UserSettingsSerializer

  describe "V1.UserSettingsSerializer" do
    test "serialized data contains a list of tokens" do
      settings = %{tokens: build_list(3, :token)}
      serialized = UserSettingsSerializer.serialize(settings)

      assert serialized.object == "setting"
      assert Map.has_key?(serialized, :tokens)
      assert is_list(serialized.tokens)
      assert length(serialized.tokens) == 3
    end
  end
end
