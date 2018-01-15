defmodule KuberaAdmin.V1.UserSerializerTest do
  use KuberaAdmin.SerializerCase, :v1
  alias KuberaAdmin.V1.UserSerializer
  alias Kubera.Web.Paginator

  describe "to_json/1" do
    test "serializes a user into correct JSON format" do
      user = build(:user)

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
        provider_user_id: user.provider_user_id,
        email: user.email,
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        }
      }

      assert UserSerializer.to_json(user) == expected
    end

    test "serializes a user paginator into a list object" do
      user1 = build(:user)
      user2 = build(:user)
      paginator = %Paginator{
        data: [user1, user2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "user",
            id: user1.id,
            username: user1.username,
            provider_user_id: user1.provider_user_id,
            email: user1.email,
            metadata: %{
              "first_name" => user1.metadata["first_name"],
              "last_name" => user1.metadata["last_name"]
            }
          },
          %{
            object: "user",
            id: user2.id,
            username: user2.username,
            provider_user_id: user2.provider_user_id,
            email: user2.email,
            metadata: %{
              "first_name" => user2.metadata["first_name"],
              "last_name" => user2.metadata["last_name"]
            }
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert UserSerializer.to_json(paginator) == expected
    end
  end
end
