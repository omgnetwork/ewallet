defmodule AdminAPI.V1.APIKeyViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias AdminAPI.V1.APIKeyView

  describe "render/2" do
    test "renders api_key.json with correct response format" do
      api_key = insert(:api_key)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "api_key",
          id: api_key.id,
          key: api_key.key,
          account_id: api_key.account.id,
          owner_app: api_key.owner_app,
          created_at: Date.to_iso8601(api_key.inserted_at),
          updated_at: Date.to_iso8601(api_key.updated_at),
          deleted_at: Date.to_iso8601(api_key.deleted_at)
        }
      }

      assert APIKeyView.render("api_key.json", %{api_key: api_key}) == expected
    end

    test "renders api_keys.json with correct response format" do
      api_key1 = insert(:api_key)
      api_key2 = insert(:api_key)

      paginator = %Paginator{
        data: [api_key1, api_key2],
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
              object: "api_key",
              id: api_key1.id,
              key: api_key1.key,
              account_id: api_key1.account.id,
              owner_app: api_key1.owner_app,
              created_at: Date.to_iso8601(api_key1.inserted_at),
              updated_at: Date.to_iso8601(api_key1.updated_at),
              deleted_at: Date.to_iso8601(api_key1.deleted_at)
            },
            %{
              object: "api_key",
              id: api_key2.id,
              key: api_key2.key,
              account_id: api_key2.account.id,
              owner_app: api_key2.owner_app,
              created_at: Date.to_iso8601(api_key2.inserted_at),
              updated_at: Date.to_iso8601(api_key2.updated_at),
              deleted_at: Date.to_iso8601(api_key2.deleted_at)
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

      assert APIKeyView.render("api_keys.json", %{api_keys: paginator}) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert APIKeyView.render("empty_response.json") == expected
    end
  end
end
