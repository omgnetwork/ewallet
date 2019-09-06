# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule LocalLedger.TransactionTest do
  use ExUnit.Case, async: true
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias LocalLedger.Transaction
  alias LocalLedgerDB.{CachedBalance, Entry, Repo}
  alias LocalLedgerDB.Transaction, as: TransactionSchema

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  defp debits do
    [
      %{
        "type" => Entry.debit_type(),
        "address" => "alice",
        "metadata" => %{},
        "amount" => 100,
        "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
      },
      %{
        "type" => Entry.debit_type(),
        "address" => "bob",
        "metadata" => %{},
        "amount" => 200,
        "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
      }
    ]
  end

  defp credits do
    [
      %{
        "type" => Entry.credit_type(),
        "address" => "carol",
        "metadata" => %{},
        "amount" => 150,
        "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
      },
      %{
        "type" => Entry.credit_type(),
        "address" => "dan",
        "metadata" => %{},
        "amount" => 150,
        "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
      }
    ]
  end

  defp genesis do
    {:ok, transaction} =
      Transaction.insert(
        %{
          "metadata" => %{},
          "entries" => debits() ++ credits(),
          "idempotency_token" => UUID.generate()
        },
        %{genesis: true}
      )

    transaction
  end

  defp pending do
    _ = genesis()

    # Continue the balances from genesis() above, now debiting 100 away from Carol and Dan.
    {:ok, transaction} =
      Transaction.insert(
        %{
          "idempotency_token" => UUID.generate(),
          "entries" => [
            %{
              "type" => Entry.debit_type(),
              "address" => "carol",
              "metadata" => %{},
              "amount" => 100,
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
            },
            %{
              "type" => Entry.credit_type(),
              "address" => "dan",
              "metadata" => %{},
              "amount" => 100,
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
            }
          ],
          "metadata" => %{}
        },
        %{status: "pending", genesis: false}
      )

    transaction
  end

  defp get_current_balance(address) do
    Entry.calculate_current_amount(address, "tok_OMG_01cbepz0mhzb042vwgaqv17cjy")
  end

  describe "all/0" do
    test "returns all transactions" do
      {:ok, inserted_transaction} = :transaction |> build |> Repo.insert()

      {:ok, entry} =
        :entry
        |> build(transaction_uuid: inserted_transaction.uuid)
        |> Repo.insert()

      {:ok, transactions} = Transaction.all()
      transaction = Enum.at(transactions, 0)
      assert transaction.uuid == inserted_transaction.uuid
      assert transaction.entries == [entry]
    end
  end

  describe "get/1" do
    test "returns the specified transaction" do
      {:ok, inserted_transaction} = :transaction |> build |> Repo.insert()

      {:ok, entry} =
        :entry
        |> build(transaction_uuid: inserted_transaction.uuid)
        |> Repo.insert()

      {:ok, transaction} = Transaction.get(inserted_transaction.uuid)
      assert transaction.uuid == inserted_transaction.uuid
      assert transaction.entries == [entry]
    end
  end

  describe "get_by_idempotency_token/1" do
    test "returns the specified transaction" do
      inserted = insert(:transaction)
      {res, transaction} = Transaction.get_by_idempotency_token(inserted.idempotency_token)

      assert res == :ok
      assert transaction.uuid == inserted.uuid
    end
  end

  describe "insert/3" do
    test "inserts a transaction and two entries when genesis" do
      transaction = genesis()

      assert transaction != nil
      assert length(transaction.entries) == 4
      assert get_current_balance("alice") == -100
      assert get_current_balance("bob") == -200
      assert get_current_balance("carol") == 150
      assert get_current_balance("dan") == 150
    end

    test "inserts a transaction and two entries when the debit wallets have enough funds" do
      genesis()

      {:ok, transaction} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: false}
        )

      assert transaction != nil
      assert length(transaction.entries) == 2
      assert get_current_balance("dan") == 50
      assert get_current_balance("carol") == 250
    end

    test "returns the same transaction when the idempotency token is already in the DB" do
      genesis_transaction = genesis()

      {status, transaction} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => genesis_transaction.idempotency_token
          },
          %{genesis: false}
        )

      assert status == :ok
      assert transaction.uuid == genesis_transaction.uuid
    end

    test "returns a 'same address' error when the from/to addresses are identical" do
      genesis()

      res =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: false}
        )

      assert res == {
               :error,
               :same_address,
               "Found identical addresses in senders and receivers: dan."
             }
    end

    test "returns an 'insufficient_funds' error when the debit wallets don't have enough funds" do
      genesis()

      {:error, :insufficient_funds, _} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "returns an 'invalid_amount' error when amount is invalid (debit != credit)" do
      genesis()

      {:error, :invalid_amount, _} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "returns an 'amount_is_zero' error when amount is 0" do
      genesis()

      {:error, :amount_is_zero, _} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "dan",
                "metadata" => %{},
                "amount" => 0,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 0,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: false}
        )
    end

    test "updates the wallets one after the other with two inserts happening
          at the same time" do
      genesis()
      pid = self()

      assert get_current_balance("dan") == 150
      assert get_current_balance("carol") == 150
      assert get_current_balance("bob") == -200

      {:ok, new_pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000

          assert get_current_balance("dan") == 50
          assert get_current_balance("carol") == 250
          assert get_current_balance("bob") == -200

          # this should block until the other entry commit
          Transaction.insert(
            %{
              "metadata" => %{},
              "entries" => [
                %{
                  "type" => Entry.debit_type(),
                  "address" => "dan",
                  "metadata" => %{},
                  "amount" => 50,
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                },
                %{
                  "type" => Entry.credit_type(),
                  "address" => "bob",
                  "metadata" => %{},
                  "amount" => 50,
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                }
              ],
              "idempotency_token" => UUID.generate()
            },
            %{genesis: false}
          )

          send(pid, :updated)
        end)

      Transaction.insert(
        %{
          "metadata" => %{},
          "entries" => [
            %{
              "type" => Entry.debit_type(),
              "address" => "dan",
              "metadata" => %{},
              "amount" => 100,
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
            },
            %{
              "type" => Entry.credit_type(),
              "address" => "carol",
              "metadata" => %{},
              "amount" => 100,
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
            }
          ],
          "idempotency_token" => UUID.generate()
        },
        %{genesis: false},
        fn ->
          send(new_pid, :select_for_update)
        end
      )

      assert_receive :updated, 5000
      assert get_current_balance("dan") == 0
      assert get_current_balance("carol") == 250
      assert get_current_balance("bob") == -150
    end

    test "returns an InsufficientFundsError with many inserts happening at the
          same time and not enough funds" do
      genesis()
      caller_pid = self()
      num_spawns = 200
      amount_per_transaction = 2
      timeout_ms = 10_000

      balance_dan = get_current_balance("dan")
      balance_carol = get_current_balance("carol")
      balance_bob = get_current_balance("bob")

      assert balance_dan == 150
      assert balance_carol == 150
      assert balance_bob == -200

      # Mederic has 150 units, sending 1 units per transaction should result in
      # exactly 150 successful transactions, the rest (= num_spawns - successful) should fail.

      tasks =
        for _ <- 1..num_spawns do
          Task.async(fn ->
            # Sleeps a random number between 0 - 100 ms to better simulate concurrency
            Process.sleep(:rand.uniform(10) * 10)

            Sandbox.allow(Repo, caller_pid, self())

            Transaction.insert(
              %{
                "metadata" => %{},
                "entries" => [
                  %{
                    "type" => Entry.debit_type(),
                    "address" => "dan",
                    "metadata" => %{},
                    "amount" => amount_per_transaction,
                    "token" => %{
                      "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                      "metadata" => %{}
                    }
                  },
                  %{
                    "type" => Entry.credit_type(),
                    "address" => "bob",
                    "metadata" => %{},
                    "amount" => amount_per_transaction,
                    "token" => %{
                      "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                      "metadata" => %{}
                    }
                  }
                ],
                "idempotency_token" => UUID.generate()
              },
              %{genesis: false}
            )
          end)
        end

      # Collect all the results
      results = Task.yield_many(tasks, timeout_ms)

      # For the sake of simplicity, assuming that within 10000ms all tasks would have returned,
      # so there's no need to handle with `Task.shutdown/2` and so on.
      assert length(results) == num_spawns

      # Split the results into a list of :ok results and a list of :error results.
      # Here we simply skip the information returned by `Task.yield_many/2` and
      # focus on the return from the actual transaction calls.
      {ok_results, error_results} =
        Enum.split_with(results, fn
          {_task, {_status, {:ok, _}}} -> true
          {_task, {_status, {:error, _, _}}} -> false
        end)

      # Assert the number of :ok/:error results
      num_ok_results = length(ok_results)
      num_error_results = length(error_results)

      expected_ok_results = Integer.floor_div(balance_dan, amount_per_transaction)
      expected_error_results = num_spawns - expected_ok_results

      assert num_ok_results == expected_ok_results
      assert num_error_results == expected_error_results

      # Assert that all :error results are because of :insufficient_funds
      assert Enum.all?(error_results, fn
               {_task, {_status, {:error, :insufficient_funds, _}}} -> true
               _ -> false
             end)

      # Assert the balances
      transferred_amount = num_ok_results * amount_per_transaction
      assert get_current_balance("dan") == balance_dan - transferred_amount
      assert get_current_balance("carol") == balance_carol
      assert get_current_balance("bob") == balance_bob + transferred_amount
    end

    test "handles integers up to 1 trillion * 1e18" do
      {:ok, transaction} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "alice",
                "metadata" => %{},
                "amount" => 1_000_000_000_000_000_000_000_000_000_000,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "carol",
                "metadata" => %{},
                "amount" => 1_000_000_000_000_000_000_000_000_000_000,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              }
            ],
            "idempotency_token" => UUID.generate()
          },
          %{genesis: true}
        )

      assert transaction != nil
      assert length(transaction.entries) == 2
      assert get_current_balance("alice") == -1_000_000_000_000_000_000_000_000_000_000
      assert get_current_balance("carol") == 1_000_000_000_000_000_000_000_000_000_000
    end

    test "fails for integers above 1e37" do
      assert_raise Postgrex.Error, fn ->
        {:ok, _} =
          Transaction.insert(
            %{
              "metadata" => %{},
              "entries" => [
                %{
                  "type" => Entry.debit_type(),
                  "address" => "alice",
                  "metadata" => %{},
                  "amount" => round(1.0e37),
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                },
                %{
                  "type" => Entry.credit_type(),
                  "address" => "carol",
                  "metadata" => %{},
                  "amount" => round(1.0e37),
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                }
              ],
              "idempotency_token" => UUID.generate()
            },
            %{genesis: true}
          )
      end
    end
  end

  describe "confirm/1" do
    test "returns the confirmed transaction and entries" do
      transaction = pending()
      assert transaction.status == TransactionSchema.pending()
      assert length(transaction.entries) > 1
      assert Enum.all?(transaction.entries, fn e -> e.status == Entry.pending() end)

      {res, confirmed} = Transaction.confirm(transaction.uuid)

      assert res == :ok
      assert confirmed.status == TransactionSchema.confirmed()
      assert Enum.all?(confirmed.entries, fn e -> e.status == Entry.confirmed() end)
    end
  end

  describe "fail/1" do
    test "returns the failed transaction and entries" do
      transaction = pending()
      assert transaction.status == TransactionSchema.pending()
      assert length(transaction.entries) > 1
      assert Enum.all?(transaction.entries, fn e -> e.status == Entry.pending() end)

      {res, confirmed} = Transaction.fail(transaction.uuid)

      assert res == :ok
      assert confirmed.status == TransactionSchema.failed()
      assert Enum.all?(confirmed.entries, fn e -> e.status == Entry.failed() end)
    end

    test "invalidates cache balances after the failed transaction" do
      transaction = pending()

      # Inserts a mock cached balance for testing
      address = Enum.at(transaction.entries, 0).wallet_address
      computed_at = NaiveDateTime.add(transaction.inserted_at, 60 * 60, :second)
      cached_balance = insert(:cached_balance, wallet_address: address, computed_at: computed_at)
      assert Repo.get(CachedBalance, cached_balance.uuid)

      {:ok, _} = Transaction.fail(transaction.uuid)
      refute Repo.get(CachedBalance, cached_balance.uuid)
    end
  end
end
