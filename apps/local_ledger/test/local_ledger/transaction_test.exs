# Copyright 2018 OmiseGO Pte Ltd
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
  alias LocalLedgerDB.{Entry, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "#all" do
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

  describe "#get" do
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

  describe "#insert" do
    defp debits do
      [
        %{
          "type" => Entry.debit_type(),
          "address" => "o",
          "metadata" => %{},
          "amount" => 100,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        },
        %{
          "type" => Entry.debit_type(),
          "address" => "sirn",
          "metadata" => %{},
          "amount" => 200,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        }
      ]
    end

    def credits do
      [
        %{
          "type" => Entry.credit_type(),
          "address" => "thibault",
          "metadata" => %{},
          "amount" => 150,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        },
        %{
          "type" => Entry.credit_type(),
          "address" => "mederic",
          "metadata" => %{},
          "amount" => 150,
          "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
        }
      ]
    end

    def genesis do
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

    def get_current_balance(address) do
      Entry.calculate_current_amount(address, "tok_OMG_01cbepz0mhzb042vwgaqv17cjy")
    end

    test "inserts a transaction and two entries when genesis" do
      transaction = genesis()

      assert transaction != nil
      assert length(transaction.entries) == 4
      assert get_current_balance("o") == -100
      assert get_current_balance("sirn") == -200
      assert get_current_balance("thibault") == 150
      assert get_current_balance("mederic") == 150
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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
      assert get_current_balance("mederic") == 50
      assert get_current_balance("thibault") == 250
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 100,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "mederic",
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
               "Found identical addresses in senders and receivers: mederic."
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 200,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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
                "address" => "mederic",
                "metadata" => %{},
                "amount" => 0,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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

          # this should block until the other entry commit
          Transaction.insert(
            %{
              "metadata" => %{},
              "entries" => [
                %{
                  "type" => Entry.debit_type(),
                  "address" => "mederic",
                  "metadata" => %{},
                  "amount" => 50,
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                },
                %{
                  "type" => Entry.credit_type(),
                  "address" => "sirn",
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
              "address" => "mederic",
              "metadata" => %{},
              "amount" => 100,
              "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
            },
            %{
              "type" => Entry.credit_type(),
              "address" => "thibault",
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
      assert get_current_balance("mederic") == 0
      assert get_current_balance("thibault") == 250
      assert get_current_balance("sirn") == -150
    end

    test "returns an InsufficientFundsError with many inserts happening at the
          same time and not enough funds" do
      genesis()
      caller_pid = self()
      num_spawns = 200
      amount_per_transaction = 2
      timeout_ms = 10_000

      balance_mederic = get_current_balance("mederic")
      balance_thibault = get_current_balance("thibault")
      balance_sirn = get_current_balance("sirn")

      assert balance_mederic == 150
      assert balance_thibault == 150
      assert balance_sirn == -200

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
                    "address" => "mederic",
                    "metadata" => %{},
                    "amount" => amount_per_transaction,
                    "token" => %{
                      "id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy",
                      "metadata" => %{}
                    }
                  },
                  %{
                    "type" => Entry.credit_type(),
                    "address" => "sirn",
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

      expected_ok_results = Integer.floor_div(balance_mederic, amount_per_transaction)
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
      assert get_current_balance("mederic") == balance_mederic - transferred_amount
      assert get_current_balance("thibault") == balance_thibault
      assert get_current_balance("sirn") == balance_sirn + transferred_amount
    end

    test "handles integers up to 1 trillion * 1e18" do
      {:ok, transaction} =
        Transaction.insert(
          %{
            "metadata" => %{},
            "entries" => [
              %{
                "type" => Entry.debit_type(),
                "address" => "o",
                "metadata" => %{},
                "amount" => 1_000_000_000_000_000_000_000_000_000_000,
                "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
              },
              %{
                "type" => Entry.credit_type(),
                "address" => "thibault",
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
      assert get_current_balance("o") == -1_000_000_000_000_000_000_000_000_000_000
      assert get_current_balance("thibault") == 1_000_000_000_000_000_000_000_000_000_000
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
                  "address" => "o",
                  "metadata" => %{},
                  "amount" => round(1.0e37),
                  "token" => %{"id" => "tok_OMG_01cbepz0mhzb042vwgaqv17cjy", "metadata" => %{}}
                },
                %{
                  "type" => Entry.credit_type(),
                  "address" => "thibault",
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
end
