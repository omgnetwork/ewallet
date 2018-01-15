defmodule CaishenMQ.V1.Operators.Balance do
  @moduledoc """
  Balance operator (similar to a web controller) receive and handles operations.
  """
  alias CaishenMQ.ErrorHandler
  alias CaishenMQ.V1.Serializers.{Balance, Response}

  @doc """
  Retrieve the list of all the balances for a specific address.

  ## Payload

    {
      "operation": "v1.balances.all"
    }

  """
  def operate("all", %{"address" => address}) do
    address
    |> Caishen.Balance.all()
    |> serialize_balances(address)
  end
  def operate("all", attrs), do: ErrorHandler.invalid_data(attrs)
  @doc """
  Retrieve the list of all the balances for a specific address and token friendly_id.

  ## Payload

    {
      "operation": "v1.balances.get"
    }

  """
  def operate("get", %{"address" => address, "friendly_id" => _} = attrs) do
    attrs
    |> Caishen.Balance.get()
    |> serialize_balances(address)
  end
  def operate("get", attrs), do: ErrorHandler.invalid_data(attrs)
  def operate(_, attrs), do: ErrorHandler.invalid_operation(attrs)

  defp serialize_balances(balances, address) do
    balances
    |> Balance.serialize(address)
    |> Response.serialize(success: true)
  end
end
