defmodule AdminAPI.V1.TransactionViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.TokenSerializer
  alias AdminAPI.V1.TransactionView

  describe "AdminAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct response structure" do
      transaction = insert(:transaction)

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
            amount: transaction.from_amount,
            account: nil,
            account_id: nil,
            user: nil,
            user_id: nil,
            token_id: transaction.from_token.id,
            token: TokenSerializer.serialize(transaction.from_token)
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.to_amount,
            account: nil,
            account_id: nil,
            user: nil,
            user_id: nil,
            token_id: transaction.to_token.id,
            token: TokenSerializer.serialize(transaction.to_token)
          },
          exchange: %{
            object: "exchange",
            rate: 1,
            calculated_at: nil,
            exchange_pair: nil,
            exchange_pair_id: nil
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
      transaction1 = insert(:transaction)
      transaction2 = insert(:transaction)

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
                amount: transaction1.from_amount,
                account: nil,
                account_id: nil,
                user: nil,
                user_id: nil,
                token_id: transaction1.from_token.id,
                token: TokenSerializer.serialize(transaction1.from_token)
              },
              to: %{
                object: "transaction_source",
                address: transaction1.to,
                amount: transaction1.to_amount,
                account: nil,
                account_id: nil,
                user: nil,
                user_id: nil,
                token_id: transaction1.to_token.id,
                token: TokenSerializer.serialize(transaction1.to_token)
              },
              exchange: %{
                object: "exchange",
                rate: 1,
                calculated_at: nil,
                exchange_pair: nil,
                exchange_pair_id: nil
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
                amount: transaction2.from_amount,
                account: nil,
                account_id: nil,
                user: nil,
                user_id: nil,
                token_id: transaction2.from_token.id,
                token: TokenSerializer.serialize(transaction2.from_token)
              },
              to: %{
                object: "transaction_source",
                address: transaction2.to,
                amount: transaction2.to_amount,
                account: nil,
                account_id: nil,
                user: nil,
                user_id: nil,
                token_id: transaction2.to_token.id,
                token: TokenSerializer.serialize(transaction2.to_token)
              },
              exchange: %{
                object: "exchange",
                rate: 1,
                calculated_at: nil,
                exchange_pair: nil,
                exchange_pair_id: nil
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
