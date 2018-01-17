defmodule AdminAPI.V1.AuthTokenSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.AuthTokenSerializer

  describe "AuthTokenSerializer.to_json/1" do
    test "data contains the session token" do
      attrs = %{auth_token: "the_auth_token", user: %{id: "the_user_id"}}
      serialized = AuthTokenSerializer.to_json(attrs)

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == "the_auth_token"
      assert serialized.user_id == "the_user_id"
    end
  end
end
