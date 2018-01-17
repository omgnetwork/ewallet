defmodule AdminAPI.V1.UserSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.UserSerializer
  alias EWallet.Web.{Date, Paginator}

  describe "to_json/1" do
    test "serializes a user into correct JSON format" do
      user = insert(:user)

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
        provider_user_id: user.provider_user_id,
        email: user.email,
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        created_at: Date.to_iso8601(user.inserted_at),
        updated_at: Date.to_iso8601(user.updated_at)
      }

      assert UserSerializer.to_json(user) == expected
    end

    test "serializes a user paginator into a list object" do
      user1 = insert(:user)
      user2 = insert(:user)

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
            },
            created_at: Date.to_iso8601(user1.inserted_at),
            updated_at: Date.to_iso8601(user1.updated_at)
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
            },
            created_at: Date.to_iso8601(user2.inserted_at),
            updated_at: Date.to_iso8601(user2.updated_at)
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
