defmodule AdminAPI.V1.AuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias AdminAPI.V1.AuthTokenSerializer

  describe "AuthTokenSerializer.serialize/1" do
    test "data contains the session token" do
      auth_token = insert(:auth_token)
      serialized = AuthTokenSerializer.serialize(auth_token)

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == auth_token.token
      assert serialized.user_id == auth_token.user.id
      assert serialized.user != nil
    end
  end
end
