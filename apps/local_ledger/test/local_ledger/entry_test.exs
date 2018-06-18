defmodule LocalLedger.EntryTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedger.Entry
  alias LocalLedgerDB.{Repo, Transaction, Errors.InsufficientFundsError}
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "#build_all" do
    test "builds and formats the entries" do
      debits = [
        %{
          "address" => "omisego.test.sender1",
          "metadata" => %{},
          "amount" => 100,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        }
      ]

      credits = [
        %{
          "address" => "omisego.test.receiver1",
          "metadata" => %{},
          "amount" => 100,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        }
      ]

      incoming_entries = {debits, credits}
      formatted_entries = Entry.build_all(incoming_entries)

      assert formatted_entries == [
               %{
                 type: LocalLedgerDB.Entry.debit_type(),
                 amount: 100,
                 token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                 wallet_address: "omisego.test.sender1"
               },
               %{
                 type: LocalLedgerDB.Entry.credit_type(),
                 amount: 100,
                 token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                 wallet_address: "omisego.test.receiver1"
               }
             ]
    end
  end

  describe "#get_addresses" do
    test "returns the list of debit addresses" do
      entries = [
        %{
          type: LocalLedgerDB.Entry.debit_type(),
          amount: 100,
          token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
          wallet_address: "omisego.test.sender1"
        },
        %{
          type: LocalLedgerDB.Entry.credit_type(),
          amount: 100,
          token_id: "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
          wallet_address: "omisego.test.receiver1"
        }
      ]

      addresses = Entry.get_addresses(entries)
      assert addresses == ["omisego.test.sender1"]
    end
  end

  describe "#check_funds" do
    defp init_debit_wallets(amount_1, amount_2) do
      {:ok, token} = :token |> build |> Repo.insert()
      {:ok, wallet_1} = :wallet |> build(address: "test1") |> Repo.insert()
      {:ok, wallet_2} = :wallet |> build(address: "test2") |> Repo.insert()
      {:ok, wallet_3} = :wallet |> build(address: "test3") |> Repo.insert()

      Transaction.insert(%{
        metadata: %{},
        idempotency_token: UUID.generate(),
        entries: [
          %{
            type: LocalLedgerDB.Entry.credit_type(),
            amount: amount_1,
            token_id: token.id,
            wallet_address: wallet_1.address
          },
          %{
            type: LocalLedgerDB.Entry.credit_type(),
            amount: amount_2,
            token_id: token.id,
            wallet_address: wallet_2.address
          }
        ]
      })

      {token, wallet_1, wallet_2, wallet_3}
    end

    test "raises an InsufficientFundsError if one of the debit wallets does
          not have enough funds" do
      {token, wallet_1, wallet_2, wallet_3} = init_debit_wallets(80, 100)

      entries = [
        %{
          type: LocalLedgerDB.Entry.debit_type(),
          amount: 100,
          token_id: token.id,
          wallet_address: wallet_1.address
        },
        %{
          type: LocalLedgerDB.Entry.debit_type(),
          amount: 100,
          token_id: token.id,
          wallet_address: wallet_2.address
        },
        %{
          type: LocalLedgerDB.Entry.credit_type(),
          amount: 200,
          token_id: token.id,
          wallet_address: wallet_3.address
        }
      ]

      assert_raise InsufficientFundsError, fn ->
        Entry.check_balance(entries)
      end
    end

    test "returns :ok when all the debit wallets have enough funds" do
      {token, wallet_1, wallet_2, wallet_3} = init_debit_wallets(200, 100)

      entries = [
        %{
          type: LocalLedgerDB.Entry.debit_type(),
          amount: 100,
          token_id: token.id,
          wallet_address: wallet_1.address
        },
        %{
          type: LocalLedgerDB.Entry.debit_type(),
          amount: 100,
          token_id: token.id,
          wallet_address: wallet_2.address
        },
        %{
          type: LocalLedgerDB.Entry.credit_type(),
          amount: 100,
          token_id: token.id,
          wallet_address: wallet_3.address
        }
      ]

      res = Entry.check_balance(entries)
      assert res == :ok
    end
  end
end
