defmodule LocalLedger.EntryTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedger.{Entry, Errors.InvalidAmountError}
  alias LocalLedgerDB.{Repo, Transaction, Errors.InsufficientFundsError}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "#all" do
    test "returns all entries" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert
      {:ok, transaction} = :transaction
                           |> build(entry_id: inserted_entry.id)
                           |> Repo.insert

      entry = Enum.at(Entry.all, 0)
      assert entry.id == inserted_entry.id
      assert entry.transactions == [transaction]
    end
  end

  describe "#get" do
    test "returns the specified entry" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert
      {:ok, transaction} = :transaction
                           |> build(entry_id: inserted_entry.id)
                           |> Repo.insert

      entry = Entry.get(inserted_entry.id)
      assert entry.id == inserted_entry.id
      assert entry.transactions == [transaction]
    end
  end

  describe "#insert" do
    defp debits do
      [%{
        "address" => "o",
        "metadata" => %{},
        "amount" => 100
      }, %{
        "address" => "sirn",
        "metadata" => %{},
        "amount" => 200
      }]
    end

    def credits do
      [%{
        "address" => "thibault",
        "metadata" => %{},
        "amount" => 150
      }, %{
        "address" => "mederic",
        "metadata" => %{},
        "amount" => 150
      }]
    end

    def genesis do
      {:ok, entry} = Entry.insert(%{
        "metadata" => %{},
        "debits" => debits(),
        "credits" => credits(),
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => UUID.generate
      }, true)

      entry
    end

    def get_current_balance(address) do
      Transaction.calculate_current_amount(address, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
    end

    test "inserts an entry and four transactions when genesis" do
      entry = genesis()

      assert entry != nil
      assert length(entry.transactions) == 4
      assert get_current_balance("o") == -100
      assert get_current_balance("sirn") == -200
      assert get_current_balance("thibault") == 150
      assert get_current_balance("mederic") == 150
    end

    test "inserts an entry and four transactions when the debit balances have
          enough funds" do
      genesis()

      {:ok, entry} = Entry.insert(%{
        "metadata" => %{},
        "debits" => [%{
          "address" => "mederic",
          "metadata" => %{},
          "amount" => 100
        }],
        "credits" => [%{
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 100
        }],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => UUID.generate
      })

      assert entry != nil
      assert length(entry.transactions) == 2
      assert get_current_balance("mederic") == 50
      assert get_current_balance("thibault") == 250
    end

    test "fails when the correlation_id is already in the database" do
      genesis_entry = genesis()

      {status, error} = Entry.insert(%{
        "metadata" => %{},
        "debits" => [%{
          "address" => "mederic",
          "metadata" => %{},
          "amount" => 100
        }],
        "credits" => [%{
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 100
        }],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => genesis_entry.correlation_id
      })

      assert status == :error
      assert error.errors == [correlation_id: {"has already been taken", []}]
    end

    test "raises an InsufficientFundsError when the debit balances don't have
          enough funds" do
      genesis()

      assert_raise InsufficientFundsError, fn ->
        Entry.insert(%{
          "metadata" => %{},
          "debits" => [%{
            "address" => "mederic",
            "metadata" => %{},
            "amount" => 200
          }],
          "credits" => [%{
            "address" => "thibault",
            "metadata" => %{},
            "amount" => 200
          }],
          "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
          "correlation_id" => UUID.generate
        })
      end
    end

    test "raises an InvalidAmountError when amount is invalid
          (debit != credit)" do
      genesis()

      assert_raise InvalidAmountError, fn ->
        Entry.insert(%{
          "metadata" => %{},
          "debits" => [%{
            "address" => "mederic",
            "metadata" => %{},
            "amount" => 200
          }],
          "credits" => [%{
            "address" => "thibault",
            "metadata" => %{},
            "amount" => 100
          }],
          "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
          "correlation_id" => UUID.generate
        })
      end
    end

    test "updates the balances one after the other with two inserts happening
          at the same time" do
      genesis()
      pid = self()

      assert get_current_balance("mederic") == 150
      assert get_current_balance("thibault") == 150
      assert get_current_balance("sirn") == -200

      {:ok, new_pid} = Task.start_link fn ->
        Sandbox.allow(Repo, pid, self())
        assert_receive :select_for_update, 5000

        assert get_current_balance("mederic") == 50
        assert get_current_balance("thibault") == 250
        assert get_current_balance("sirn") == -200

        # this should block until the other transaction commit
        Entry.insert(%{
          "metadata" => %{},
          "debits" => [%{"address" => "mederic", "metadata" => %{}, "amount" => 50}],
          "credits" => [%{"address" => "sirn", "metadata" => %{}, "amount" => 50}],
          "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
          "correlation_id" => UUID.generate
        })

        send pid, :updated
      end

      Entry.insert(%{
        "metadata" => %{},
        "debits" => [%{"address" => "mederic", "metadata" => %{}, "amount" => 100}],
        "credits" => [%{"address" => "thibault", "metadata" => %{}, "amount" => 100}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => UUID.generate
      }, false, fn ->
        send new_pid, :select_for_update
      end)

      assert_receive :updated, 5000
      assert get_current_balance("mederic") == 0
      assert get_current_balance("thibault") == 250
      assert get_current_balance("sirn") == -150
    end

    test "raises an InsufficientFundsError with two inserts happening at the
          same time and not enough funds" do
      genesis()
      pid = self()

      assert get_current_balance("mederic") == 150
      assert get_current_balance("thibault") == 150
      assert get_current_balance("sirn") == -200

      {:ok, new_pid} = Task.start_link fn ->
        Sandbox.allow(Repo, pid, self())
        assert_receive :select_for_update, 5000

        assert_raise InsufficientFundsError, fn ->
          # this should block until the other transaction commit
          Entry.insert(%{
            "metadata" => %{},
            "debits" => [%{
              "address" => "mederic",
              "metadata" => %{},
              "amount" => 100
            }],
            "credits" => [%{
              "address" => "sirn",
              "metadata" => %{},
              "amount" => 100
            }],
            "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
            "correlation_id" => UUID.generate
          })
        end
        send pid, :updated
      end

      send new_pid, :select_for_update
      Entry.insert(%{
        "metadata" => %{},
        "debits" => [%{
          "address" => "mederic",
          "metadata" => %{},
          "amount" => 100
        }],
        "credits" => [%{
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 100
        }],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => UUID.generate
      })

      assert_receive :updated, 5000
      assert get_current_balance("mederic") == 50
      assert get_current_balance("thibault") == 250
      assert get_current_balance("sirn") == -200
    end

    test "handles integers up to 1 trillion * 1e18" do
      {:ok, entry} = Entry.insert(%{
        "metadata" => %{},
        "debits" => [%{
          "address" => "o",
          "metadata" => %{},
          "amount" => 1_000_000_000_000_000_000_000_000_000_000
        }],
        "credits" => [%{
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 1_000_000_000_000_000_000_000_000_000_000
        }],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
        "correlation_id" => UUID.generate
      }, true)

      assert entry != nil
      assert length(entry.transactions) == 2
      assert get_current_balance("o") ==
        -1_000_000_000_000_000_000_000_000_000_000
      assert get_current_balance("thibault") ==
        1_000_000_000_000_000_000_000_000_000_000
    end

    test "fails for integers above 1 trillion * 1e81" do

      assert_raise Postgrex.Error, fn ->
        {:ok, _} = Entry.insert(%{
          "metadata" => %{},
          "debits" => [%{
            "address" => "o",
            "metadata" => %{},
            "amount" => round(1_000_000_000_000.0e82)
          }],
          "credits" => [%{
            "address" => "thibault",
            "metadata" => %{},
            "amount" => round(1_000_000_000_000.0e82)
          }],
          "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}},
          "correlation_id" => UUID.generate
        }, true)
      end
    end
  end
end
