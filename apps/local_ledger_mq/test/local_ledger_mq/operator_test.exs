defmodule LocalLedgerMQ.OperatorTest do
  use ExUnit.Case
  alias LocalLedgerDB.Repo
  alias LocalLedgerMQ.Operator
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "operate/1" do
    test "dispatches to the appropriate operator" do
      payload = Poison.encode!(%{operation: "v1.entry.all"})
      entries = Operator.operate(payload, "123")

      assert Poison.decode!(entries) == %{
        "success" => true,
        "data" => %{"data" => [], "object" => "list"}
      }
    end

    test "raises an error when an invalid payload is provided" do
      error = Operator.operate("{\"operation\":\"aa}", "123")
      assert Poison.decode!(error) == %{
        "success" => false,
        "data" => %{
          "code" => "client:invalid_payload",
          "description" => "Could not decode payload as JSON.",
          "object" => "error"
        }
      }
    end

    test "returns an invalid operation if the operator is not found" do
      error = Operator.operate(~s({\"operation\":\"v1.foo.all\"}), "123")
      assert Poison.decode!(error) == %{
        "success" => false,
        "data" => %{
          "code" => "client:invalid_operation",
          "description" => "The operation 'v1.foo.all' was not found.",
          "object" => "error"
        }
      }
    end

    test "returns a no version error if no version is specified" do
      error = Operator.operate(~s({\"operation\":\"entry.all\"}), "123")
      assert Poison.decode!(error) == %{
        "success" => false,
        "data" => %{
          "code" => "client:no_version",
          "description" => "No version given.",
          "object" => "error"
        }
      }
    end

    test "returns an invalid version error if an unkown version is specified" do
      error = Operator.operate(~s({\"operation\":\"vx.entry.all\"}), "123")
      assert Poison.decode!(error) == %{
        "success" => false,
        "data" => %{
          "code" => "client:invalid_version",
          "description" => "The version 'vx' was not found.",
          "object" => "error"
        }
      }
    end
  end
end
