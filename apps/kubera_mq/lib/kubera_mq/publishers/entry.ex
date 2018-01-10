defmodule KuberaMQ.Publishers.Entry do
  @moduledoc """
  Interface to the ledger Entry records.
  """
  alias KuberaMQ.Publisher

  def all do
    Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue), %{
      operation: "v1.entry.all"
    })
  end

  def get(id) do
    Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue), %{
      operation: "v1.entry.get",
      data: %{id: id}
    })
  end

  def insert(data, idempotency_token) do
    Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue), %{
      idempotency_token: idempotency_token,
      operation: "v1.entry.insert",
      data: data
    })
  end

  def genesis(data, idempotency_token) do
    Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue), %{
      idempotency_token: idempotency_token,
      operation: "v1.entry.genesis",
      data: data
    })
  end
end
