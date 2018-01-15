defmodule CaishenMQ.V1.Serializers.Balance do
  @moduledoc """
  Balance serializer used for formatting.
  """

  def serialize(nil), do: %{}
  def serialize(balances, address) do
    %{
      object: "balance",
      address: address,
      amounts: balances
    }
  end
end
