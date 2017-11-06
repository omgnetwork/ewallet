defmodule KuberaAPI.V1.BalanceView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{BalanceSerializer, ListSerializer,
                           ResponseSerializer}

  def render("balances.json", %{balances: balances}) do
    balances
    |> Enum.map(fn balance -> BalanceSerializer.serialize(balance) end)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
