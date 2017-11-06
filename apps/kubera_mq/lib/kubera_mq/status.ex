defmodule KuberaMQ.Status do
  @moduledoc """
  Interface to the ledger Entry records.
  """
  alias KuberaMQ.Publisher

  def check do
    attrs = %{operation: "status.check"}
    Publisher.send(attrs)
  end
end
