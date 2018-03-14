defmodule EWalletAPI.V1.UserSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWalletAPI.V1.UserSerializer

  describe "serialize/1" do
    test "serializes into correct V1 user format" do
      user = insert(:user)

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
        provider_user_id: user.provider_user_id,
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        encrypted_metadata: %{}
      }

      assert UserSerializer.serialize(user) == expected
    end

    test "serializes to nil if user is not given" do
      assert UserSerializer.serialize(nil) == nil
    end

    test "serializes to nil if user is not loaded" do
      assert UserSerializer.serialize(%NotLoaded{}) == nil
    end
  end
end
