defmodule AdminAPI.V1.UserViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias AdminAPI.V1.UserView

  describe "AdminAPI.V1.UserView.render/2" do
    test "renders user.json with correct response structure" do
      user = insert(:user)

      # I prefer to keep this test code duplicate with the `UserView.render/2` test,
      # because in practice they are separate responses.
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.external_id,
          socket_topic: "user:#{user.external_id}",
          username: user.username,
          provider_user_id: user.provider_user_id,
          email: user.email,
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          metadata: %{
            "first_name" => user.metadata["first_name"],
            "last_name" => user.metadata["last_name"]
          },
          encrypted_metadata: %{},
          created_at: Date.to_iso8601(user.inserted_at),
          updated_at: Date.to_iso8601(user.updated_at)
        }
      }

      assert UserView.render("user.json", %{user: user}) == expected
    end

    test "renders users.json with correct response structure" do
      user1 = insert(:user)
      user2 = insert(:user)

      paginator = %Paginator{
        data: [user1, user2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false,
        },
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            %{
              object: "user",
              id: user1.external_id,
              socket_topic: "user:#{user1.external_id}",
              username: user1.username,
              provider_user_id: user1.provider_user_id,
              email: user1.email,
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{
                "first_name" => user1.metadata["first_name"],
                "last_name" => user1.metadata["last_name"]
              },
              encrypted_metadata: %{},
              created_at: Date.to_iso8601(user1.inserted_at),
              updated_at: Date.to_iso8601(user1.updated_at)
            },
            %{
              object: "user",
              id: user2.external_id,
              socket_topic: "user:#{user2.external_id}",
              username: user2.username,
              provider_user_id: user2.provider_user_id,
              email: user2.email,
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{
                "first_name" => user2.metadata["first_name"],
                "last_name" => user2.metadata["last_name"]
              },
              encrypted_metadata: %{},
              created_at: Date.to_iso8601(user2.inserted_at),
              updated_at: Date.to_iso8601(user2.updated_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: false,
          },
        }
      }

      assert UserView.render("users.json", %{users: paginator}) == expected
    end
  end
end
