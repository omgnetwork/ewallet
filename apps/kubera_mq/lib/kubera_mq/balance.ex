defmodule KuberaMQ.Balance do
  @moduledoc """
  Interface to the ledger Transactions records.
  """
  alias KuberaMQ.Publisher

  def all(address) do
    Publisher.send(%{
      operation: "v1.balance.all",
      address: address
    })
  end

  def get(friendly_id, address) do
    Publisher.send(%{
      operation: "v1.balance.get",
      friendly_id: friendly_id,
      address: address
    })
  end
end
