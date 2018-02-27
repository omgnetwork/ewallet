defmodule AdminAPI.V1.TransactionViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias AdminAPI.V1.TransactionView

  describe "AdminAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct response structure" do
      transaction = insert(:transfer)
      minted_token = transaction.minted_token

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "transaction",
          id: transaction.id,
          idempotency_token: transaction.idempotency_token,
          from: %{
            object: "transaction_source",
            address: transaction.from,
            amount: transaction.amount,
            minted_token: %{
              object: "minted_token",
              id: minted_token.friendly_id,
              symbol: minted_token.symbol,
              name: minted_token.name,
              subunit_to_unit: minted_token.subunit_to_unit,
              created_at: Date.to_iso8601(minted_token.inserted_at),
              updated_at: Date.to_iso8601(minted_token.updated_at)
            },
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.amount,
            minted_token: %{
              object: "minted_token",
              id: minted_token.friendly_id,
              symbol: minted_token.symbol,
              name: minted_token.name,
              subunit_to_unit: minted_token.subunit_to_unit,
              created_at: Date.to_iso8601(minted_token.inserted_at),
              updated_at: Date.to_iso8601(minted_token.updated_at)
            },
          },
          exchange: %{
            object: "exchange",
            rate: 1,
          },
          status: transaction.status,
          created_at: Date.to_iso8601(transaction.inserted_at),
          updated_at: Date.to_iso8601(transaction.updated_at)
        }
      }

      assert TransactionView.render("transaction.json", %{transaction: transaction}) == expected
    end

    test "renders transactions.json with correct response structure" do
      transaction1  = insert(:transfer)
      minted_token1 = transaction1.minted_token
      transaction2  = insert(:transfer)
      minted_token2 = transaction2.minted_token

      paginator = %Paginator{
        data: [transaction1, transaction2],
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
              object: "transaction",
              id: transaction1.id,
              idempotency_token: transaction1.idempotency_token,
              from: %{
                object: "transaction_source",
                address: transaction1.from,
                amount: transaction1.amount,
                minted_token: %{
                  object: "minted_token",
                  id: minted_token1.friendly_id,
                  symbol: minted_token1.symbol,
                  name: minted_token1.name,
                  subunit_to_unit: minted_token1.subunit_to_unit,
                  created_at: Date.to_iso8601(minted_token1.inserted_at),
                  updated_at: Date.to_iso8601(minted_token1.updated_at)
                },
              },
              to: %{
                object: "transaction_source",
                address: transaction1.to,
                amount: transaction1.amount,
                minted_token: %{
                  object: "minted_token",
                  id: minted_token1.friendly_id,
                  symbol: minted_token1.symbol,
                  name: minted_token1.name,
                  subunit_to_unit: minted_token1.subunit_to_unit,
                  created_at: Date.to_iso8601(minted_token1.inserted_at),
                  updated_at: Date.to_iso8601(minted_token1.updated_at)
                },
              },
              exchange: %{
                object: "exchange",
                rate: 1,
              },
              status: transaction1.status,
              created_at: Date.to_iso8601(transaction1.inserted_at),
              updated_at: Date.to_iso8601(transaction1.updated_at)
            },
            %{
              object: "transaction",
              id: transaction2.id,
              idempotency_token: transaction2.idempotency_token,
              from: %{
                object: "transaction_source",
                address: transaction2.from,
                amount: transaction2.amount,
                minted_token: %{
                  object: "minted_token",
                  id: minted_token2.friendly_id,
                  symbol: minted_token2.symbol,
                  name: minted_token2.name,
                  subunit_to_unit: minted_token2.subunit_to_unit,
                  created_at: Date.to_iso8601(minted_token2.inserted_at),
                  updated_at: Date.to_iso8601(minted_token2.updated_at)
                },
              },
              to: %{
                object: "transaction_source",
                address: transaction2.to,
                amount: transaction2.amount,
                minted_token: %{
                  object: "minted_token",
                  id: minted_token2.friendly_id,
                  symbol: minted_token2.symbol,
                  name: minted_token2.name,
                  subunit_to_unit: minted_token2.subunit_to_unit,
                  created_at: Date.to_iso8601(minted_token2.inserted_at),
                  updated_at: Date.to_iso8601(minted_token2.updated_at)
                },
              },
              exchange: %{
                object: "exchange",
                rate: 1,
              },
              status: transaction2.status,
              created_at: Date.to_iso8601(transaction2.inserted_at),
              updated_at: Date.to_iso8601(transaction2.updated_at)
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

      assert TransactionView.render("transactions.json", %{transactions: paginator}) == expected
    end
  end
end
