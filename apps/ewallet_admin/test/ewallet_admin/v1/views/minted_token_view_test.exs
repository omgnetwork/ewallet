defmodule EWalletAdmin.V1.MintedTokenViewTest do
  use EWalletAdmin.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias EWalletAdmin.V1.MintedTokenView

  describe "EWalletAdmin.V1.MintedTokenView.render/2" do
    test "renders minted_token.json with correct response structure" do
      minted_token = insert(:minted_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "minted_token",
          id: minted_token.friendly_id,
          symbol: minted_token.symbol,
          name: minted_token.name,
          subunit_to_unit: minted_token.subunit_to_unit,
          created_at: Date.to_iso8601(minted_token.inserted_at),
          updated_at: Date.to_iso8601(minted_token.updated_at)
        }
      }

      assert MintedTokenView.render("minted_token.json", %{minted_token: minted_token}) == expected
    end

    test "renders minted_tokens.json with correct response structure" do
      minted_token1 = insert(:minted_token)
      minted_token2 = insert(:minted_token)

      paginator = %Paginator{
        data: [minted_token1, minted_token2],
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
              object: "minted_token",
              id: minted_token1.friendly_id,
              symbol: minted_token1.symbol,
              name: minted_token1.name,
              subunit_to_unit: minted_token1.subunit_to_unit,
              created_at: Date.to_iso8601(minted_token1.inserted_at),
              updated_at: Date.to_iso8601(minted_token1.updated_at)
            },
            %{
              object: "minted_token",
              id: minted_token2.friendly_id,
              symbol: minted_token2.symbol,
              name: minted_token2.name,
              subunit_to_unit: minted_token2.subunit_to_unit,
              created_at: Date.to_iso8601(minted_token2.inserted_at),
              updated_at: Date.to_iso8601(minted_token2.updated_at)
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

      assert MintedTokenView.render("minted_tokens.json", %{minted_tokens: paginator}) == expected
    end
  end
end
