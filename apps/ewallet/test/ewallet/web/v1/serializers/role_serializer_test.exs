defmodule EWallet.Web.V1.RoleSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{RoleSerializer, UserSerializer}

  describe "serialize/1" do
    test "serializes a role into V1 response format" do
      role = :role |> insert() |> Repo.preload([:users])

      expected = %{
        object: "role",
        id: role.id,
        name: role.name,
        priority: role.priority,
        display_name: role.display_name,
        user_ids: UserSerializer.serialize(role.users, :id),
        users: UserSerializer.serialize(role.users),
        created_at: Date.to_iso8601(role.inserted_at),
        updated_at: Date.to_iso8601(role.updated_at)
      }

      assert RoleSerializer.serialize(role) == expected
    end

    test "serializes a role paginator into a list object" do
      role1 = :role |> insert() |> Repo.preload([:users])
      role2 = :role |> insert() |> Repo.preload([:users])

      paginator = %Paginator{
        data: [role1, role2],
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
            object: "role",
            id: role1.id,
            name: role1.name,
            priority: role1.priority,
            display_name: role1.display_name,
            user_ids: UserSerializer.serialize(role1.users, :id),
            users: UserSerializer.serialize(role1.users),
            created_at: Date.to_iso8601(role1.inserted_at),
            updated_at: Date.to_iso8601(role1.updated_at)
          },
          %{
            object: "role",
            id: role2.id,
            name: role2.name,
            priority: role2.priority,
            display_name: role2.display_name,
            user_ids: UserSerializer.serialize(role2.users, :id),
            users: UserSerializer.serialize(role2.users),
            created_at: Date.to_iso8601(role2.inserted_at),
            updated_at: Date.to_iso8601(role2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          is_first_page: false,
          is_last_page: true,
          per_page: 7
        }
      }

      assert RoleSerializer.serialize(paginator) == expected
    end

    test "serializes to nil if role is not given" do
      assert RoleSerializer.serialize(nil) == nil
    end

    test "serializes to nil if role is not loaded" do
      assert RoleSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes an empty role paginator into a list object" do
      paginator = %Paginator{
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert RoleSerializer.serialize(paginator) == expected
    end
  end

  describe "serialize/2" do
    test "serializes roles to ids" do
      roles = [role1, role2] = insert_list(2, :role)
      assert RoleSerializer.serialize(roles, :id) == [role1.id, role2.id]
    end
  end
end
