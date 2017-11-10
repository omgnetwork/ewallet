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

  def get(symbol, address) do
    Publisher.send(%{
      operation: "v1.balance.get",
      symbol: symbol,
      address: address
    })
  end
end
