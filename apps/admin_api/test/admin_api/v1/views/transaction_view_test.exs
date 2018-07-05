defmodule AdminAPI.V1.TransactionViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.TransactionView
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.{Date, V1.TokenSerializer, V1.UserSerializer, V1.AccountSerializer}
  alias EWalletDB.Helpers.Assoc

  describe "AdminAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct response structure" do
      transaction =
        insert(:transaction)
        |> Repo.preload([:from_token, :to_token, :from_user, :from_account, :to_user, :to_account])

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
            account: AccountSerializer.serialize(transaction.from_account),
            account_id: Assoc.get(transaction, [:from_account, :id]),
            user: UserSerializer.serialize(transaction.from_user),
            user_id: Assoc.get(transaction, [:from_user, :id]),
            token_id: transaction.from_token.id,
            token: TokenSerializer.serialize(transaction.from_token)
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.to_amount,
            account: AccountSerializer.serialize(transaction.to_account),
            account_id: Assoc.get(transaction, [:to_account, :id]),
            user: UserSerializer.serialize(transaction.to_user),
            user_id: Assoc.get(transaction, [:to_user, :id]),
            token_id: transaction.to_token.id,
            token: TokenSerializer.serialize(transaction.to_token)
          },
          exchange: %{
            object: "exchange",
            rate: 1,
            calculated_at: nil,
            exchange_pair: nil,
            exchange_pair_id: nil,
            exchange_account: nil,
            exchange_account_id: nil,
            exchange_wallet: nil,
            exchange_wallet_address: nil
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
      transaction1 =
        insert(:transaction)
        |> Repo.preload([:from_token, :to_token, :from_user, :from_account, :to_user, :to_account])

      transaction2 =
        insert(:transaction)
        |> Repo.preload([:from_token, :to_token, :from_user, :from_account, :to_user, :to_account])

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
                account: AccountSerializer.serialize(transaction1.from_account),
                account_id: Assoc.get(transaction1, [:from_account, :id]),
                user: UserSerializer.serialize(transaction1.from_user),
                user_id: Assoc.get(transaction1, [:from_user, :id]),
                token_id: transaction1.from_token.id,
                token: TokenSerializer.serialize(transaction1.from_token)
              },
              to: %{
                object: "transaction_source",
                address: transaction1.to,
                amount: transaction1.to_amount,
                account: AccountSerializer.serialize(transaction1.to_account),
                account_id: Assoc.get(transaction1, [:to_account, :id]),
                user: UserSerializer.serialize(transaction1.to_user),
                user_id: Assoc.get(transaction1, [:to_user, :id]),
                token_id: transaction1.to_token.id,
                token: TokenSerializer.serialize(transaction1.to_token)
              },
              exchange: %{
                object: "exchange",
                rate: 1,
                calculated_at: nil,
                exchange_pair: nil,
                exchange_pair_id: nil,
                exchange_account: nil,
                exchange_account_id: nil,
                exchange_wallet: nil,
                exchange_wallet_address: nil
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
                account: AccountSerializer.serialize(transaction2.from_account),
                account_id: Assoc.get(transaction2, [:from_account, :id]),
                user: UserSerializer.serialize(transaction2.from_user),
                user_id: Assoc.get(transaction2, [:from_user, :id]),
                token_id: transaction2.from_token.id,
                token: TokenSerializer.serialize(transaction2.from_token)
              },
              to: %{
                object: "transaction_source",
                address: transaction2.to,
                amount: transaction2.to_amount,
                account: AccountSerializer.serialize(transaction2.to_account),
                account_id: Assoc.get(transaction2, [:to_account, :id]),
                user: UserSerializer.serialize(transaction2.to_user),
                user_id: Assoc.get(transaction2, [:to_user, :id]),
                token_id: transaction2.to_token.id,
                token: TokenSerializer.serialize(transaction2.to_token)
              },
              exchange: %{
                object: "exchange",
                rate: 1,
                calculated_at: nil,
                exchange_pair: nil,
                exchange_pair_id: nil,
                exchange_account: nil,
                exchange_account_id: nil,
                exchange_wallet: nil,
                exchange_wallet_address: nil
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
