defmodule AdminAPI.V1.KeySerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.KeySerializer
  alias EWallet.Web.{Date, Paginator}

  describe "serialize/1" do
    test "serializes a key into the correct response format" do
      key = insert(:key)

      expected = %{
        object: "key",
        id: key.id,
        access_key: key.access_key,
        secret_key: key.secret_key,
        account_id: key.account_id,
        created_at: Date.to_iso8601(key.inserted_at),
        updated_at: Date.to_iso8601(key.updated_at),
        deleted_at: Date.to_iso8601(key.deleted_at)
      }

      assert KeySerializer.serialize(key) == expected
    end

    test "serializes a key paginator into a list object" do
      key1 = insert(:key)
      key2 = insert(:key)

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
            account_id: key1.account_id,
            created_at: Date.to_iso8601(key1.inserted_at),
            updated_at: Date.to_iso8601(key1.updated_at),
            deleted_at: Date.to_iso8601(key1.deleted_at)
          },
          %{
            object: "key",
            id: key2.id,
            access_key: key2.access_key,
            secret_key: key2.secret_key,
            account_id: key2.account_id,
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
