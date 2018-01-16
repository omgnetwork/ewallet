defmodule LocalLedgerMQ.ConsumerTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.Repo
  alias LocalLedgerMQ.Publisher
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
    Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "connects to LocalLedger through RabbitMQ, gets the list of entries" do
    {:ok, inserted_entry} = :entry |> build |> Repo.insert
    {:ok, _} = :transaction
               |> build(entry_id: inserted_entry.id)
               |> Repo.insert

    {:ok, response} = Publisher.publish(
      Application.get_env(:local_ledger_mq, :mq_ledger_queue),
      %{operation: "v1.entry.all"}
    )

    assert Enum.at(response["data"], 0)["id"] ==
            inserted_entry.id
  end

  test "receives an error when the operator does not exist" do
    {res, code, operation} = Publisher.publish(
      Application.get_env(:local_ledger_mq, :mq_ledger_queue),
      %{operation: "v1.fake.all"}
    )

    assert res == :error
    assert code == "client:invalid_operation"
    assert operation == "The operation 'v1.fake.all' was not found."
  end

  test "receives an error when the operation does not exist" do
    {res, code, operation} = Publisher.publish(
      Application.get_env(:local_ledger_mq, :mq_ledger_queue),
      %{operation: "v1.entry.fake"}
    )

    assert res == :error
    assert code == "client:invalid_operation"
    assert operation == "The operation 'v1.entry.fake' was not found."
  end

  test "receives an no_operation error when sending an empty payload" do
    {res, code, operation} = Publisher.publish(
      Application.get_env(:local_ledger_mq, :mq_ledger_queue),
      %{}
    )

    assert res == :error
    assert code == "client:no_operation"
    assert operation == "No operation given."
  end
end
