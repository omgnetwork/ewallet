defmodule KuberaAdmin.V1.UserSerializerTest do
  use KuberaAdmin.SerializerCase, :v1
  alias KuberaAdmin.V1.UserSerializer
  alias Ecto.UUID

  describe "to_json/1" do
    test "serializes user into correct JSON format" do
      user = %{
        id: UUID.generate(),
        username: "johndoe",
        provider_user_id: "provider_id_1234",
        email: "example@omise.co",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
        provider_user_id: user.provider_user_id,
        email: user.email,
        metadata: %{
          first_name: user.metadata.first_name,
          last_name: user.metadata.last_name
        }
      }

      assert UserSerializer.to_json(user) == expected
    end
  end
end
