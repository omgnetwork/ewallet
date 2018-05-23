defmodule EWalletAPI.V1.AuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletAPI.V1.AuthTokenSerializer

  describe "V1.AuthTokenSerializer" do
    test "data contains the authentication token" do
      auth_token = insert(:auth_token)
      serialized = AuthTokenSerializer.serialize(auth_token)

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == auth_token.token
    end
  end
end
