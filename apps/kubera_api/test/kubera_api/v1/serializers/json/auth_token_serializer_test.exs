defmodule KuberaAPI.V1.AuthTokenSerializerTest do
  use KuberaAPI.SerializerCase, :v1
  alias KuberaAPI.V1.JSON.AuthTokenSerializer

  describe "V1.JSON.AuthTokenSerializer" do
    test "data contains the authentication token" do
      serialized = AuthTokenSerializer.serialize("the_auth_token")

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == "the_auth_token"
    end
  end
end
