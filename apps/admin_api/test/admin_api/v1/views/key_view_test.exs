defmodule AdminAPI.V1.KeyViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.KeyView
  alias EWallet.Web.{Date, Paginator}
  alias EWalletDB.Helpers.Preloader

  describe "render/2" do
    test "renders key.json with correct response format" do
      key = :key |> insert() |> Preloader.preload(:account)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
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
      }

      assert KeyView.render("key.json", %{key: key}) == expected
    end

    test "renders keys.json with correct response format" do
      key1 = :key |> insert() |> Preloader.preload(:account)
      key2 = :key |> insert() |> Preloader.preload(:account)

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
        version: @expected_version,
        success: true,
        data: %{
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
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: true
          }
        }
      }

      assert KeyView.render("keys.json", %{keys: paginator}) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert KeyView.render("empty_response.json") == expected
    end
  end
end
