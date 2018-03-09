defmodule EWalletAPI.V1.AuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletAPI.V1.AuthTokenSerializer

  describe "V1.AuthTokenSerializer" do
    test "data contains the authentication token" do
      serialized = AuthTokenSerializer.serialize("the_auth_token")

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == "the_auth_token"
    end
  end
end
