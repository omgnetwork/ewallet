defmodule CaishenMQ.V1.Operators.BalanceTest do
  use ExUnit.Case
  alias CaishenMQ.V1.Operators.{Entry, Balance}
  alias CaishenDB.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
    Sandbox.mode(Repo, {:shared, self()})
  end

  defp transfer(operation, from, to, amount, friendly_id) do
    data = %{
      "metadata" => %{},
      "debits" => [%{"address" => from, "amount" => amount, "metadata" => %{}}],
      "credits" => [%{"address" => to, "amount" => amount, "metadata" => %{}}],
      "minted_token" => %{"friendly_id" => friendly_id, "metadata" => %{}}
    }
    Entry.operate(operation, %{
      "operation" => operation,
      "data" => data,
      "correlation_id" => "#{from}_#{to}_#{friendly_id}"
    })
  end

  describe "operate/2 when 'all'" do
    test "returns an empty list when there are no balances" do
      attrs = %{"operation" => "v1.balance.all", "address" => "foo"}
      assert Balance.operate("all", attrs) == %{
        success: true,
        data: %{address: "foo", amounts: %{}, object: "balance"}
      }
    end

    test "returns an error when no address specified" do
      attrs = %{"operation" => "v1.balance.all"}
      assert Balance.operate("all", attrs) == %{
        success: false,
        data: %{object: "error",
                code: "client:invalid_data",
                description: "The submitted data were not valid.",
                messages: attrs}
      }
    end

    defp balances_for(address) do
      %{success: res, data: data} = Balance.operate("all", %{
        "operation" => "v1.balance.all",
        "address" => address
      })

      assert res == true
      data
    end

    test "returns the list of balances" do
      transfer("genesis", "genesis", "master", 10_000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("genesis", "genesis", "master", 10_000, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")
      transfer("genesis", "genesis", "master", 10_000, "BTC:209d3f5b-eab4-4906-9697-c482009fc865")

      transfer("insert", "master", "123", 1000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "master", "123", 500, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "123", "456", 100, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "123", "456", 150, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "master", "456", 150, "BTC:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "456", "123", 150, "BTC:209d3f5b-eab4-4906-9697-c482009fc865")

      assert balances_for("master") == %{
        object: "balance",
        address: "master",
        amounts: %{"BTC:209d3f5b-eab4-4906-9697-c482009fc865" => 9850, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 9500, "OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 9000}
      }

      assert balances_for("123") == %{
        object: "balance",
        address: "123",
        amounts: %{"BTC:209d3f5b-eab4-4906-9697-c482009fc865" => 150, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 350, "OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 900}
      }

      assert balances_for("456") == %{
        object: "balance",
        address: "456",
        amounts: %{"BTC:209d3f5b-eab4-4906-9697-c482009fc865" => 0, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 150, "OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 100}
      }
    end
  end

  describe "operate/2 when 'get'" do
    test "returns an empty list when there are no balances" do
      transfer("genesis", "genesis", "master", 10_000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")

      attrs = %{"operation" => "v1.balance.get",
                "address" => "foo",
                "friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865"}
      assert Balance.operate("get", attrs) == %{
        success: true,
        data: %{address: "foo", amounts: %{}, object: "balance"}
      }
    end

    test "returns an empty list when there are no friendly_id" do
      transfer("genesis", "genesis", "master", 10_000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")

      transfer("insert", "master", "123", 1000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")

      attrs = %{"operation" => "v1.balance.get",
                "address" => "master",
                "friendly_id" => "foo"}
      assert Balance.operate("get", attrs) == %{
        success: true,
        data: %{address: "master", amounts: %{}, object: "balance"}
      }
    end

    test "returns an error if no friendly_id specified" do
      attrs = %{"operation" => "v1.balance.get",
                "address" => "foo"}
      assert Balance.operate("get", attrs) == %{
        success: false,
        data: %{object: "error",
                code: "client:invalid_data",
                description: "The submitted data were not valid.",
                messages: attrs}
      }
    end

    test "returns an error if no address specified" do
      attrs = %{"operation" => "v1.balance.get",
                "friendly_id" => "OMG:209d3f5b-eab4-4906-9697-c482009fc865"}
      assert Balance.operate("get", attrs) == %{
        success: false,
        data: %{object: "error",
                code: "client:invalid_data",
                description: "The submitted data were not valid.",
                messages: attrs}
      }
    end

    defp balances_for(address, friendly_id) do
      %{success: res, data: data} = Balance.operate("get", %{
        "operation" => "v1.balance.get",
        "address" => address,
        "friendly_id" => friendly_id
      })

      assert res == true
      data
    end

    test "returns the list of balances for the specified friendly_id" do
      transfer("genesis", "genesis", "master", 10_000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("genesis", "genesis", "master", 10_000, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")

      transfer("insert", "master", "123", 1000, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "master", "123", 200, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "123", "456", 100, "OMG:209d3f5b-eab4-4906-9697-c482009fc865")
      transfer("insert", "123", "456", 150, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865")

      assert balances_for("master", "OMG:209d3f5b-eab4-4906-9697-c482009fc865") == %{
        object: "balance",
        address: "master",
        amounts: %{"OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 9000}
      }

      assert balances_for("master", "KNC:310-d3f5b-eab4-4906-9697-c482009fc865") == %{
        object: "balance",
        address: "master",
        amounts: %{"KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 9800}
      }

      assert balances_for("123", "OMG:209d3f5b-eab4-4906-9697-c482009fc865") == %{
        object: "balance",
        address: "123",
        amounts: %{"OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 900}
      }

      assert balances_for("456", "KNC:310-d3f5b-eab4-4906-9697-c482009fc865") == %{
        object: "balance",
        address: "456",
        amounts: %{"KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 150}
      }
    end
  end

  describe "operate/2 when invalid operation" do
    test "returns an invalid_operation error" do
      assert Entry.operate("foo", %{"operation" => "v1.balance.foo"}) == %{
        success: false,
        data: %{
          code: "client:invalid_operation",
          description: "The operation 'v1.balance.foo' was not found.",
          object: "error"
        }
      }
    end
  end
end
