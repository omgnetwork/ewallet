defmodule AdminAPI.V1.TransactionViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias AdminAPI.V1.TransactionView

  describe "AdminAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct response structure" do
      transaction = insert(:transfer)
      token = transaction.token

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
            token_id: token.id,
            token: %{
              object: "token",
              id: token.id,
              symbol: token.symbol,
              name: token.name,
              metadata: %{},
              encrypted_metadata: %{},
              subunit_to_unit: token.subunit_to_unit,
              created_at: Date.to_iso8601(token.inserted_at),
              updated_at: Date.to_iso8601(token.updated_at)
            }
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.amount,
            token_id: token.id,
            token: %{
              object: "token",
              id: token.id,
              symbol: token.symbol,
              name: token.name,
              metadata: %{},
              encrypted_metadata: %{},
              subunit_to_unit: token.subunit_to_unit,
              created_at: Date.to_iso8601(token.inserted_at),
              updated_at: Date.to_iso8601(token.updated_at)
            }
          },
          exchange: %{
            object: "exchange",
            rate: 1
          },
          metadata: %{some: "metadata"},
          encrypted_metadata: %{},
          status: transaction.status,
          created_at: Date.to_iso8601(transaction.inserted_at),
          updated_at: Date.to_iso8601(transaction.updated_at)
        }
      }

      assert TransactionView.render("transaction.json", %{transaction: transaction}) == expected
    end

    test "renders transactions.json with correct response structure" do
      transaction1 = insert(:transfer)
      token1 = transaction1.token
      transaction2 = insert(:transfer)
      token2 = transaction2.token

      paginator = %Paginator{
        data: [transaction1, transaction2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
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
                token_id: token1.id,
                token: %{
                  object: "token",
                  id: token1.id,
                  symbol: token1.symbol,
                  name: token1.name,
                  metadata: %{},
                  encrypted_metadata: %{},
                  subunit_to_unit: token1.subunit_to_unit,
                  created_at: Date.to_iso8601(token1.inserted_at),
                  updated_at: Date.to_iso8601(token1.updated_at)
                }
              },
              to: %{
                object: "transaction_source",
                address: transaction1.to,
                amount: transaction1.amount,
                token_id: token1.id,
                token: %{
                  object: "token",
                  id: token1.id,
                  symbol: token1.symbol,
                  name: token1.name,
                  metadata: %{},
                  encrypted_metadata: %{},
                  subunit_to_unit: token1.subunit_to_unit,
                  created_at: Date.to_iso8601(token1.inserted_at),
                  updated_at: Date.to_iso8601(token1.updated_at)
                }
              },
              exchange: %{
                object: "exchange",
                rate: 1
              },
              metadata: %{some: "metadata"},
              encrypted_metadata: %{},
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
                token_id: token2.id,
                token: %{
                  object: "token",
                  id: token2.id,
                  symbol: token2.symbol,
                  name: token2.name,
                  metadata: %{},
                  encrypted_metadata: %{},
                  subunit_to_unit: token2.subunit_to_unit,
                  created_at: Date.to_iso8601(token2.inserted_at),
                  updated_at: Date.to_iso8601(token2.updated_at)
                }
              },
              to: %{
                object: "transaction_source",
                address: transaction2.to,
                amount: transaction2.amount,
                token_id: token2.id,
                token: %{
                  object: "token",
                  id: token2.id,
                  symbol: token2.symbol,
                  name: token2.name,
                  metadata: %{},
                  encrypted_metadata: %{},
                  subunit_to_unit: token2.subunit_to_unit,
                  created_at: Date.to_iso8601(token2.inserted_at),
                  updated_at: Date.to_iso8601(token2.updated_at)
                }
              },
              exchange: %{
                object: "exchange",
                rate: 1
              },
              metadata: %{some: "metadata"},
              encrypted_metadata: %{},
              status: transaction2.status,
              created_at: Date.to_iso8601(transaction2.inserted_at),
              updated_at: Date.to_iso8601(transaction2.updated_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: false
          }
        }
      }

      assert TransactionView.render("transactions.json", %{transactions: paginator}) == expected
    end
  end
end
