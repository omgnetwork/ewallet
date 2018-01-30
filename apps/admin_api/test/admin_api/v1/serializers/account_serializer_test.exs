defmodule AdminAPI.V1.AccountSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.AccountSerializer
  alias EWallet.Web.{Paginator, Date}

  describe "AccountSerializer.to_json/1" do
    test "serializes an account into V1 response format" do
      account = insert(:account)

      expected = %{
        object: "account",
        id: account.id,
        parent_id: account.parent_id,
        name: account.name,
        description: account.description,
        master: account.master,
        avatar: %{original: nil},
        created_at: Date.to_iso8601(account.inserted_at),
        updated_at: Date.to_iso8601(account.updated_at)
      }

      assert AccountSerializer.to_json(account) == expected
    end

    test "serializes an account paginator into a list object" do
      account1 = insert(:account)
      account2 = insert(:account)
      paginator = %Paginator{
        data: [account1, account2],
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
            object: "account",
            id: account1.id,
            parent_id: account1.parent_id,
            name: account1.name,
            description: account1.description,
            master: account1.master,
            avatar: %{original: nil},
            created_at: Date.to_iso8601(account1.inserted_at),
            updated_at: Date.to_iso8601(account1.updated_at)
          },
          %{
            object: "account",
            id: account2.id,
            parent_id: account2.parent_id,
            name: account2.name,
            description: account2.description,
            master: account2.master,
            avatar: %{original: nil},
            created_at: Date.to_iso8601(account2.inserted_at),
            updated_at: Date.to_iso8601(account2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert AccountSerializer.to_json(paginator) == expected
    end

    test "serializes to nil if account is not given" do
      assert AccountSerializer.to_json(nil) == nil
    end

    test "serializes an empty account paginator into a list object" do
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

      assert AccountSerializer.to_json(paginator) == expected
    end
  end
end
