defmodule EWallet.Web.V1.KeySerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.KeySerializer

  describe "serialize/1" do
    test "serializes a key into the correct response format" do
      key = :key |> insert() |> Repo.preload(:account)

      expected = %{
        object: "key",
        id: key.id,
        access_key: key.access_key,
        secret_key: key.secret_key,
        account_id: key.account.id,
        expired: key.expired,
        created_at: Date.to_iso8601(key.inserted_at),
        updated_at: Date.to_iso8601(key.updated_at),
        deleted_at: Date.to_iso8601(key.deleted_at)
      }

      assert KeySerializer.serialize(key) == expected
    end

    test "serializes to nil if the key is not loaded" do
      assert KeySerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes a key paginator into a list object" do
      key1 = :key |> insert() |> Repo.preload(:account)
      key2 = :key |> insert() |> Repo.preload(:account)

      paginator = %Paginator{
        data: [key1, key2],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "key",
            id: key1.id,
            access_key: key1.access_key,
            secret_key: key1.secret_key,
            account_id: key1.account.id,
            expired: key1.expired,
            created_at: Date.to_iso8601(key1.inserted_at),
            updated_at: Date.to_iso8601(key1.updated_at),
            deleted_at: Date.to_iso8601(key1.deleted_at)
          },
          %{
            object: "key",
            id: key2.id,
            access_key: key2.access_key,
            secret_key: key2.secret_key,
            account_id: key2.account.id,
            expired: key2.expired,
            created_at: Date.to_iso8601(key2.inserted_at),
            updated_at: Date.to_iso8601(key2.updated_at),
            deleted_at: Date.to_iso8601(key2.deleted_at)
          }
        ],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert KeySerializer.serialize(paginator) == expected
    end
  end
end
