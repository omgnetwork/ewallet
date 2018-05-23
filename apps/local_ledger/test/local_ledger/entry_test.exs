defmodule LocalLedger.EntryTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedger.Entry
  alias LocalLedgerDB.{Repo, Transaction}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "#all" do
    test "returns all entries" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert()

      {:ok, transaction} =
        :transaction
        |> build(entry_uuid: inserted_entry.uuid)
        |> Repo.insert()

      {:ok, entries} = Entry.all()
      entry = Enum.at(entries, 0)
      assert entry.uuid == inserted_entry.uuid
      assert entry.transactions == [transaction]
    end
  end

  describe "#get" do
    test "returns the specified entry" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert()

      {:ok, transaction} =
        :transaction
        |> build(entry_uuid: inserted_entry.uuid)
        |> Repo.insert()

      {:ok, entry} = Entry.get(inserted_entry.uuid)
      assert entry.uuid == inserted_entry.uuid
      assert entry.transactions == [transaction]
    end
  end

  describe "#insert" do
    defp debits do
      [
        %{
          "address" => "o",
          "metadata" => %{},
          "amount" => 100
        },
        %{
          "address" => "sirn",
          "metadata" => %{},
          "amount" => 200
        }
      ]
    end

    def credits do
      [
        %{
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 150
        },
        %{
          "address" => "mederic",
          "metadata" => %{},
          "amount" => 150
        }
      ]
    end

    def genesis do
      {:ok, entry} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => debits(),
            "credits" => credits(),
            "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
            "correlation_id" => UUID.generate()
          },
          %{genesis: true}
        )

      entry
    end

    def get_current_balance(address) do
      Transaction.calculate_current_amount(address, "tok_OMG_01cbepz0mhzb042vwgaqv17cjy")
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

    test "inserts an entry and four transactions when the debit wallets have
          enough funds" do
      genesis()

      {:ok, entry} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 100
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 100
              }
            ],
            "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
            "correlation_id" => UUID.generate()
          },
          %{genesis: false}
        )

      assert entry != nil
      assert length(entry.transactions) == 2
      assert get_current_balance("mederic") == 50
      assert get_current_balance("thibault") == 250
    end

    test "fails when the correlation_id is already in the database" do
      genesis_entry = genesis()

      {status, error} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 100
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 100
              }
            ],
            "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
            "correlation_id" => genesis_entry.correlation_id
          },
          %{genesis: false}
        )

      assert status == :error
      assert error.errors == [correlation_id: {"has already been taken", []}]
    end

    test "returns a 'same address' error when the from/to addresses are identical" do
      genesis()

      res =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200
              }
            ],
            "credits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200
              }
            ],
            "token" => %{
              "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
              "metadata" => %{}
            },
            "correlation_id" => UUID.generate()
          },
          %{genesis: false}
        )

      assert res == {
               :error,
               :same_address,
               "Found identical addresses in senders and receivers: mederic."
             }
    end

    test "returns an 'insufficient_funds' error when the debit wallets don't have enough funds" do
      genesis()

      {:error, :insufficient_funds, _} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 200
              }
            ],
            "token" => %{
              "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
              "metadata" => %{}
            },
            "correlation_id" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "returns an 'invalid_amount' error when amount is invalid (debit != credit)" do
      genesis()

      {:error, :invalid_amount, _} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 100
              }
            ],
            "token" => %{
              "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
              "metadata" => %{}
            },
            "correlation_id" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "returns an 'amount_is_zero' error when amount is 0" do
      genesis()

      {:error, :amount_is_zero, _} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 0
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 0
              }
            ],
            "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
            "correlation_id" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "updates the wallets one after the other with two inserts happening
          at the same time" do
      genesis()
      pid = self()

      assert get_current_balance("mederic") == 150
      assert get_current_balance("thibault") == 150
      assert get_current_balance("sirn") == -200

      {:ok, new_pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000

          assert get_current_balance("mederic") == 50
          assert get_current_balance("thibault") == 250
          assert get_current_balance("sirn") == -200

          # this should block until the other transaction commit
          Entry.insert(
            %{
              "metadata" => %{},
              "debits" => [%{"address" => "mederic", "metadata" => %{}, "amount" => 50}],
              "credits" => [%{"address" => "sirn", "metadata" => %{}, "amount" => 50}],
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
              "correlation_id" => UUID.generate()
            },
            %{genesis: false}
          )

          send(pid, :updated)
        end)

      Entry.insert(
        %{
          "metadata" => %{},
          "debits" => [%{"address" => "mederic", "metadata" => %{}, "amount" => 100}],
          "credits" => [%{"address" => "thibault", "metadata" => %{}, "amount" => 100}],
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
          "correlation_id" => UUID.generate()
        },
        %{genesis: false},
        fn ->
          send(new_pid, :select_for_update)
        end
      )

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

      {:ok, new_pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000

          # this should block until the other transaction commit
          {res, error, _} =
            Entry.insert(
              %{
                "metadata" => %{},
                "debits" => [
                  %{
                    "address" => "mederic",
                    "metadata" => %{},
                    "amount" => 100
                  }
                ],
                "credits" => [
                  %{
                    "address" => "sirn",
                    "metadata" => %{},
                    "amount" => 100
                  }
                ],
                "token" => %{
                  "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                  "metadata" => %{}
                },
                "correlation_id" => UUID.generate()
              },
              %{genesis: false}
            )

          assert res == :error
          assert error == :insufficient_funds
          send(pid, :updated)
        end)

      send(new_pid, :select_for_update)

      Entry.insert(
        %{
          "metadata" => %{},
          "debits" => [
            %{
              "address" => "mederic",
              "metadata" => %{},
              "amount" => 100
            }
          ],
          "credits" => [
            %{
              "address" => "thibault",
              "metadata" => %{},
              "amount" => 100
            }
          ],
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
          "correlation_id" => UUID.generate()
        },
        %{genesis: false}
      )

      assert_receive :updated, 5000
      assert get_current_balance("mederic") == 50
      assert get_current_balance("thibault") == 250
      assert get_current_balance("sirn") == -200
    end

    test "handles integers up to 1 trillion * 1e18" do
      {:ok, entry} =
        Entry.insert(
          %{
            "metadata" => %{},
            "debits" => [
              %{
                "address" => "o",
                "metadata" => %{},
                "amount" => 1_000_000_000_000_000_000_000_000_000_000
              }
            ],
            "credits" => [
              %{
                "address" => "thibault",
                "metadata" => %{},
                "amount" => 1_000_000_000_000_000_000_000_000_000_000
              }
            ],
            "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
            "correlation_id" => UUID.generate()
          },
          %{genesis: true}
        )

      assert entry != nil
      assert length(entry.transactions) == 2
      assert get_current_balance("o") == -1_000_000_000_000_000_000_000_000_000_000
      assert get_current_balance("thibault") == 1_000_000_000_000_000_000_000_000_000_000
    end

    test "fails for integers above 1 trillion * 1e81" do
      assert_raise Postgrex.Error, fn ->
        {:ok, _} =
          Entry.insert(
            %{
              "metadata" => %{},
              "debits" => [
                %{
                  "address" => "o",
                  "metadata" => %{},
                  "amount" => round(1_000_000_000_000.0e82)
                }
              ],
              "credits" => [
                %{
                  "address" => "thibault",
                  "metadata" => %{},
                  "amount" => round(1_000_000_000_000.0e82)
                }
              ],
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}},
              "correlation_id" => UUID.generate()
            },
            %{genesis: true}
          )
      end
    end
  end
end
