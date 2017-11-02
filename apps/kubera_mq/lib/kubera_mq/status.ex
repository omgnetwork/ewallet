defmodule KuberaMQ.Status do
  @moduledoc """
  Interface to the ledger Entry records.
  """
  alias KuberaMQ.Publisher

  def check(callback) do
    attrs = %{operation: "status.check"}
    Publisher.send(attrs, callback)
  end
end
