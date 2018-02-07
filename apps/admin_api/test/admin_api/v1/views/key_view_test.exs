defmodule AdminAPI.V1.KeyViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias AdminAPI.V1.KeyView

  describe "render/2" do
    test "renders keys.json with correct response format" do
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
              account_id: key1.account_id,
              created_at: Date.to_iso8601(key1.inserted_at),
              updated_at: Date.to_iso8601(key1.updated_at)
            },
            %{
              object: "key",
              id: key2.id,
              access_key: key2.access_key,
              secret_key: key2.secret_key,
              account_id: key2.account_id,
              created_at: Date.to_iso8601(key2.inserted_at),
              updated_at: Date.to_iso8601(key2.updated_at)
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
  end
end
