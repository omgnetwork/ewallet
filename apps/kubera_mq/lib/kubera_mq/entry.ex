defmodule KuberaMQ.Entry do
  @moduledoc """
  Interface to the ledger Entry records.
  """
  alias KuberaMQ.Publisher

  def all(callback) do
    attrs = %{operation: "entry.all"}
    Publisher.send(attrs, callback)
  end

  def get(id, callback) do
    attrs = %{operation: "entry.get", data: %{id: id}}
    Publisher.send(attrs, callback)
  end

  def insert(data, callback) do
    attrs = %{operation: "entry.insert", data: data}
    Publisher.send(attrs, callback)
  end

  def genesis(data, callback) do
    attrs = %{operation: "entry.genesis", data: data}
    Publisher.send(attrs, callback)
  end
end
