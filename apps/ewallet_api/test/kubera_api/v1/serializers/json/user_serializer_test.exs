defmodule EWalletAPI.V1.UserSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletAPI.V1.JSON.UserSerializer
  alias Ecto.UUID

  describe "V1.JSON.UserSerializer" do
    test "serializes into correct V1 user format" do
      user = %{
        id: UUID.generate(),
        username: "johndoe",
        provider_user_id: "provider_id_1234",
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
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      assert UserSerializer.serialize(user) == expected
    end
  end
end
