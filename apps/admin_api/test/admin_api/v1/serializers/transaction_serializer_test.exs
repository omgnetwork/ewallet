defmodule AdminAPI.V1.TransactionSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.TransactionSerializer
  alias EWallet.Web.{Date, Paginator}

  describe "Transaction.to_json/1" do
    test "serializes a transaction into V1 response format" do
      transaction = insert(:transfer)
      minted_token = transaction.minted_token

      expected = %{
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

      assert TransactionSerializer.to_json(transaction) == expected
    end

    test "serializes a transaction paginator into a list object" do
      transaction1  = insert(:transfer)
      minted_token1 = transaction1.minted_token
      transaction2  = insert(:transfer)
      minted_token2 = transaction2.minted_token

      paginator = %Paginator{
        data: [transaction1, transaction2],
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
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert TransactionSerializer.to_json(paginator) == expected
    end
  end
end
