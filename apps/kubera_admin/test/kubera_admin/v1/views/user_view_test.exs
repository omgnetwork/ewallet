defmodule KuberaAdmin.V1.UserViewTest do
  use KuberaAdmin.ViewCase, :v1
  alias Kubera.Web.Paginator
  alias KuberaAdmin.V1.UserView

  describe "KuberaAdmin.V1.UserView.render/2" do
    test "renders user.json with correct response structure" do
      user = build(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
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
      }

      assert UserView.render("user.json", %{user: user}) == expected
    end

    test "renders users.json with correct response structure" do
      user1 = build(:user)
      user2 = build(:user)

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
