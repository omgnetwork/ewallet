defmodule KuberaMQ.Entry do
  @moduledoc """
  Interface to the ledger Entry records.
  """
  alias KuberaMQ.Publisher

  def all do
    Publisher.send(%{
      operation: "v1.entry.all"
    })
  end

  def get(id) do
    Publisher.send(%{
      operation: "v1.entry.get",
      data: %{id: id}
    })
  end

  def insert(data) do
    Publisher.send(%{
      operation: "v1.entry.insert",
      data: data})
  end

  def genesis(data) do
    Publisher.send(%{
      operation: "v1.entry.genesis",
      data: data
    })
  end
end
