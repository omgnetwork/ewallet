defmodule LocalLedger.TransactionTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedger.Transaction
  alias LocalLedgerDB.{Repo, Entry, Errors.InsufficientFundsError}
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "#build_all" do
    test "builds and formats the transactions" do
      debits = [
        %{
          "address" => "omisego.test.sender1",
          "metadata" => %{},
          "amount" => 100
        }
      ]

      credits = [
        %{
          "address" => "omisego.test.receiver1",
          "metadata" => %{},
          "amount" => 100
        }
      ]

      token = %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
      incoming_transactions = {debits, credits}

      formatted_transactions = Transaction.build_all(incoming_transactions, token)

      assert formatted_transactions == [
               %{
                 type: LocalLedgerDB.Transaction.debit_type(),
                 amount: 100,
                 minted_token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                 balance_address: "omisego.test.sender1"
               },
               %{
                 type: LocalLedgerDB.Transaction.credit_type(),
                 amount: 100,
                 minted_token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                 balance_address: "omisego.test.receiver1"
               }
             ]
    end
  end

  describe "#get_addresses" do
    test "returns the list of debit addresses" do
      transactions = [
        %{
          type: LocalLedgerDB.Transaction.debit_type(),
          amount: 100,
          minted_token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
          balance_address: "omisego.test.sender1"
        },
        %{
          type: LocalLedgerDB.Transaction.credit_type(),
          amount: 100,
          minted_token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
          balance_address: "omisego.test.receiver1"
        }
      ]

      addresses = Transaction.get_addresses(transactions)
      assert addresses == ["omisego.test.sender1"]
    end
  end

  describe "#check_funds" do
    defp init_debit_balances(amount_1, amount_2) do
      {:ok, token} = :minted_token |> build |> Repo.insert()
      {:ok, balance_1} = :balance |> build(address: "test1") |> Repo.insert()
      {:ok, balance_2} = :balance |> build(address: "test2") |> Repo.insert()
      {:ok, balance_3} = :balance |> build(address: "test3") |> Repo.insert()

      Entry.insert(%{
        metadata: %{},
        correlation_id: UUID.generate(),
        transactions: [
          %{
            type: LocalLedgerDB.Transaction.credit_type(),
            amount: amount_1,
            minted_token_id: token.id,
            balance_address: balance_1.address
          },
          %{
            type: LocalLedgerDB.Transaction.credit_type(),
            amount: amount_2,
            minted_token_id: token.id,
            balance_address: balance_2.address
          }
        ]
      })

      {token, balance_1, balance_2, balance_3}
    end

    test "raises an InsufficientFundsError if one of the debit balances does
          not have enough funds" do
      {token, balance_1, balance_2, balance_3} = init_debit_balances(80, 100)

      transactions = [
        %{
          type: LocalLedgerDB.Transaction.debit_type(),
          amount: 100,
          minted_token_id: token.id,
          balance_address: balance_1.address
        },
        %{
          type: LocalLedgerDB.Transaction.debit_type(),
          amount: 100,
          minted_token_id: token.id,
          balance_address: balance_2.address
        },
        %{
          type: LocalLedgerDB.Transaction.credit_type(),
          amount: 200,
          minted_token_id: token.id,
          balance_address: balance_3.address
        }
      ]

      assert_raise InsufficientFundsError, fn ->
        Transaction.check_balance(transactions)
      end
    end

    test "returns :ok when all the debit balances have enough funds" do
      {token, balance_1, balance_2, balance_3} = init_debit_balances(200, 100)

      transactions = [
        %{
          type: LocalLedgerDB.Transaction.debit_type(),
          amount: 100,
          minted_token_id: token.id,
          balance_address: balance_1.address
        },
        %{
          type: LocalLedgerDB.Transaction.debit_type(),
          amount: 100,
          minted_token_id: token.id,
          balance_address: balance_2.address
        },
        %{
          type: LocalLedgerDB.Transaction.credit_type(),
          amount: 100,
          minted_token_id: token.id,
          balance_address: balance_3.address
        }
      ]

      res = Transaction.check_balance(transactions)
      assert res == :ok
    end
  end
end
