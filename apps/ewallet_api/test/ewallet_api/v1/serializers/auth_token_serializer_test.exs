defmodule EWalletAPI.V1.UserAuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.UserAuthTokenSerializer

  describe "V1.AuthTokenSerializer" do
    test "data contains the authentication token" do
      auth_token = insert(:auth_token)
      serialized = UserAuthTokenSerializer.serialize(auth_token)

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == auth_token.token
    end
  end
end
