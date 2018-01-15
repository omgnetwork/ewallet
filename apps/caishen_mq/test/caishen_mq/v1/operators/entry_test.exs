defmodule CaishenMQ.V1.Operators.EntryTest do
  use ExUnit.Case
  import CaishenDB.Factory
  alias CaishenMQ.V1.Operators.Entry
  alias CaishenDB.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
    Sandbox.mode(Repo, {:shared, self()})
  end

  describe "operate/2 when 'all'" do
    test "returns an empty list when there are no entries" do
      assert Entry.operate("all", %{}) == %{
        success: true,
        data: %{data: [], object: "list"}
      }
    end

    test "returns the list of entries" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert
      {:ok, transaction} = :transaction
                           |> build(entry_id: inserted_entry.id)
                           |> Repo.insert

      %{success: true, data: %{data: entries}} = Entry.operate("all", %{
        "operation" => "v1.entry.all"
      })

      entry = Enum.at(entries, 0)
      assert entry.id == inserted_entry.id
      assert Enum.at(entry.transactions, 0).id == transaction.id
    end

    test "returns the list of entries when version is not specified (v1)" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert
      {:ok, transaction} = :transaction
                           |> build(entry_id: inserted_entry.id)
                           |> Repo.insert

      %{success: true, data: %{data: entries}} = Entry.operate("all", %{
        "operation" => "entry.all"
      })

      entry = Enum.at(entries, 0)
      assert entry.id == inserted_entry.id
      assert Enum.at(entry.transactions, 0).id == transaction.id
    end
  end

  describe "operate/2 when 'get'" do
    test "returns an error when no id is provided" do
      entry = Entry.operate("get", %{
        "operation" => "get",
        "data" => %{}
      })

      assert entry == %{
        success: false,
        data: %{
          code: "client:invalid_data",
          description: "The submitted data were not valid.",
          object: "error"
        }
      }
    end

    test "returns an invalid_uuid error when the supplied id is invalid" do
      entry = Entry.operate("get", %{
        "operation" => "get",
        "data" => %{
          "id" => "123"
        }
      })

      assert entry == %{
        success: false,
        data: %{
          code: "client:invalid_uuid",
          description: "The given id ('123') is not a valid UUID.",
          object: "error"
        }
      }
    end

    test "returns a not_found error when not existing" do
      uuid = UUID.generate()

      entry = Entry.operate("get", %{
        "operation" => "get",
        "data" => %{
          "id" => uuid
        }
      })

      assert entry == %{
        success: false,
        data: %{
          code: "client:not_found",
          description: "No record was found with the id '#{uuid}'.",
          object: "error"
        }
      }
    end

    test "returns the entry when existing" do
      {:ok, inserted_entry} = :entry |> build |> Repo.insert
      {:ok, transaction} = :transaction
                           |> build(entry_id: inserted_entry.id)
                           |> Repo.insert

       entry = Entry.operate("get", %{
         "operation" => "get",
         "data" => %{
           "id" => inserted_entry.id
         }
       })

       assert entry == %{
         success: true,
         data: %{
           object: "entry",
           id: inserted_entry.id,
           correlation_id: inserted_entry.correlation_id,
           inserted_at: inserted_entry.inserted_at,
           metadata: %{"merchant_id" => "123"},
           transactions: [
             %{
               amount: 100,
               balance_address: "test",
               id: transaction.id,
               inserted_at: transaction.inserted_at,
               minted_token_friendly_id: "OMG:123",
               object: "transaction",
               type: "credit"
              }
            ]
          }
        }
    end
  end

  describe "operate/2 when 'insert'" do
    test "returns the same entry when correlation_id is already present" do
      genesis = %{
        "metadata" => %{},
        "debits" => [%{"address" => "genesis", "amount" => 100, "metadata" => %{}}],
        "credits" => [%{"address" => "123", "amount" => 100, "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }
      inserted_entry = Entry.operate("genesis", %{"operation" => "genesis",
                                                  "data" => genesis,
                                                  "correlation_id" => "123"})

      data = %{
        "metadata" => %{},
        "debits" => [%{"address" => "123",
                       "amount" => 100,
                       "metadata" => %{}}],
        "credits" => [%{"address" => "456",
                       "amount" => 100,
                       "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }

      entry = Entry.operate("insert", %{"operation" => "get",
                                       "data" => data,
                                       "correlation_id" => "123"})

      assert entry.success == true
      assert entry.data.id == inserted_entry.data.id
      assert entry.data.correlation_id == "123"
    end

    test "returns an insufficient_funds error when the debit balances don't have
          enough funds" do
      data = %{
        "metadata" => %{},
        "debits" => [%{"address" => "123",
                       "amount" => 100,
                       "metadata" => %{}}],
        "credits" => [%{"address" => "456",
                       "amount" => 100,
                       "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }

      message = "The specified balance (123) does not contain enough " <>
                "funds. Available: 0 OMG:209d3f5b-eab4-4906-9697-c482009fc865 - " <>
                "Attempted debit: 100 OMG:209d3f5b-eab4-4906-9697-c482009fc865"
      entry = Entry.operate("insert", %{"operation" => "get", "data" => data})
      assert entry == %{
        success: false,
        data: %{
          code: "client:insufficient_funds",
          description: message,
          object: "error"}
        }
    end

    test "inserts a new genesis entry" do
      genesis = %{
        "metadata" => %{},
        "debits" => [%{"address" => "genesis",
                       "amount" => 100,
                       "metadata" => %{}}],
        "credits" => [%{"address" => "123",
                       "amount" => 100,
                       "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }
      entry = Entry.operate("genesis", %{"operation" => "genesis",
                                         "data" => genesis,
                                         "correlation_id" => "123"})

      assert entry.success == true
      assert entry.data.id != nil
    end

    test "inserts and returns an entry and the related transactions" do
      genesis = %{
        "metadata" => %{},
        "debits" => [%{"address" => "genesis",
                       "amount" => 100,
                       "metadata" => %{}}],
        "credits" => [%{"address" => "123",
                        "amount" => 100,
                        "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }
      Entry.operate("genesis", %{"operation" => "genesis",
                                 "data" => genesis,
                                 "correlation_id" => "123"})

      data = %{
        "metadata" => %{},
        "debits" => [%{"address" => "123", "amount" => 100, "metadata" => %{}}],
        "credits" => [%{"address" => "456", "amount" => 100, "metadata" => %{}}],
        "minted_token" => %{"friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865", "metadata" => %{}}
      }

      entry = Entry.operate("insert", %{"operation" => "get",
                                        "data" => data,
                                        "correlation_id" => "456"})

      assert entry.success == true
      assert entry.data.id != nil
    end
  end

  describe "operate/2 when invalid operation" do
    test "returns an invalid_operation error" do
      assert Entry.operate("foo", %{"operation" => "v1.entry.foo"}) == %{
        success: false,
        data: %{
          code: "client:invalid_operation",
          description: "The operation 'v1.entry.foo' was not found.",
          object: "error"
        }
      }
    end
  end
end
